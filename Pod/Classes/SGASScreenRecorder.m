//
//  SRScreenRecorder.m
//  ScreenRecorderHackaton
//
//  Created by Shmatlay Andrey on 21.06.13.
//  Edited by Aleksandr Gusev on 23/10/14
//

#import "SGASScreenRecorder.h"
#import <AVFoundation/AVFoundation.h>
#import <UIKit/UIKit.h>
#import "SGVBackgroundRunloop.h"
#import <IOSurface/IOSurface.h>
#import <IOSurface/IOMobileFramebuffer.h>
#import <IOSurface/IOSurfaceAccelerator.h>

#pragma mark - Private Declarations
extern IOSurfaceRef CVPixelBufferGetIOSurface(CVPixelBufferRef pixelBuffer);

@interface SGASScreenRecorder () {
    AVAssetWriter *_videoWriter;
    AVAssetWriterInputPixelBufferAdaptor *_pixelBufferAdaptor;
    
    SGVBackgroundRunloop *_backgroundRunloop;
    CADisplayLink *_displayLink;
    CMTime _lastFrameTime;
    
    id _applicationDidEnterBackgroundObserver;
    
    IOSurfaceAcceleratorRef _surfaceAccelerator;
    
    IOSurfaceRef _screenSurface;
    CVPixelBufferRef _pixelBuffer;
    IOSurfaceRef _copySurface;
}

@end

@implementation SGASScreenRecorder

@dynamic recording;

#pragma mark - Init/dealloc
- (instancetype)init {
    if (![SGASScreenRecorder isSupported]) {
        return nil;
    }
    self = [super init];
    if (self) {
        if (![self getScreenSurface]) {
            return nil;
        }
    }
    return self;
}

- (void)dealloc {
    [self releaseSurfaceAccelerator];
    [self releasePixelBuffer];
    [self unsubscribeFromEnterBackgroundNotification];
}

#pragma mark - Public

+ (BOOL)isSupported {
#if TARGET_IPHONE_SIMULATOR
    return NO;
#else
    return YES;
#endif
}

- (void)startRecordingWithSettings:(SGASScreenRecorderSettings *)settings
                       toFileAtURL:(NSURL *)videoFileURL {
    NSCParameterAssert(settings);
    NSCParameterAssert([videoFileURL isFileURL]);
    if (!settings || ![videoFileURL isFileURL]) {
        return;
    }
    NSCAssert(!self.recording, @"Already recording.");
    if (self.recording) {
        return;
    }
    _lastRecordingVideoFileURL = videoFileURL;
    _lastRecordingSettings = settings;
    
    if (_lastRecordingSettings.shouldUseVerticalSynchronization) {
        if (![self createSurfaceAccelerator]) {
            return;
        }
    }
    
    if (![self recreatePixelBufferAndCopySurface]) {
        return;
    }
    
    if (![self recreateVideoWriter]) {
        return;
    }
    
    if (![self recreateVideoWriterInputAndPixelBufferAdaptor]) {
        return;
    }
    
    if (![self startWriting]) {
        return;
    }
    
    [self recreateBackgroundRunloop];
    __typeof(self) __weak wself = self;
    [_backgroundRunloop performBlock:^{
        [wself startSessionAtCurrentMediaTime];
    }];
    [self recreateDisplayLink];
    [self subscribeForEnterBackgroundNotification];
}

- (void)stopRecording {
    if (!self.recording) {
        return;
    }

    [self unsubscribeFromEnterBackgroundNotification];
    [self shutdownDisplayLink];
    __typeof(self) __weak wself = self;
    [_backgroundRunloop performBlock:^{
        __typeof(self) sself = wself;
        if (sself) {
            [sself releaseSurfaceAccelerator];
            [sself releasePixelBufferAdaptor];
            [sself releasePixelBuffer];
            [sself finishWritingWithCompletion:^{
                __typeof(self) innerSself = wself;
                if (innerSself) {
                    if (innerSself->_completionBlock) {
                        innerSself->_completionBlock(innerSself->_lastRecordingVideoFileURL);
                    }
                }
                [innerSself releaseVideoWriter];
            }];
        }
    }];
    [self shutdownBackgroundRunloop];
}

#pragma mark - Properties

- (BOOL)isRecording {
    return !!_videoWriter;
}

#pragma mark - Notifications

- (void)subscribeForEnterBackgroundNotification {
    __typeof(self) __weak wself = self;
    _applicationDidEnterBackgroundObserver =
    [[NSNotificationCenter defaultCenter] addObserverForName:UIApplicationDidEnterBackgroundNotification
                                                      object:nil
                                                       queue:[NSOperationQueue mainQueue]
                                                  usingBlock:^(NSNotification *note) {
                                                      [wself stopRecording];
                                                  }];
}

- (void)unsubscribeFromEnterBackgroundNotification {
    if (_applicationDidEnterBackgroundObserver) {
        [[NSNotificationCenter defaultCenter] removeObserver:_applicationDidEnterBackgroundObserver];
    }
}

#pragma mark - CADisplayLink

- (void)displayLinkFired:(CADisplayLink *)displayLink {
    @autoreleasepool {
        [self captureScreenshot];
    }
}

#pragma mark - Private

- (void)captureScreenshot {
    if (!_pixelBufferAdaptor.assetWriterInput.readyForMoreMediaData) {
        NSLog(@"asset writer input not ready for media data");
        return;
    }
    
    CMTime frameTime = CMTimeMakeWithSeconds(_displayLink.timestamp,
                                             (int32_t)_lastRecordingSettings.framesPerSecond);
    // Pixel buffer adapter becomes upset once one tries to feed it with a new
    // pixel buffer having the same presentation time as the previous one
    // (which makes sense), so we need to keep track of the previous presentation time.
    if (CMTimeCompare(_lastFrameTime, frameTime) >= 0) {
        return;
    }
    _lastFrameTime = frameTime;
    
    if (_copySurface) {
        if (![self performSurfaceCopy]) {
            return;
        }
    }
    
    BOOL pixelBufferAppendResult = [_pixelBufferAdaptor appendPixelBuffer:_pixelBuffer
                                                     withPresentationTime:frameTime];
    if (!pixelBufferAppendResult) {
        NSLog(@"failed to append pixel buffer");
    }
}

- (BOOL)performSurfaceCopy {
    NSCAssert(_copySurface, @"_copySurface should not be NULL");
#if TARGET_IPHONE_SIMULATOR
    IOSurfaceAcceleratorReturn transferSurfaceResult = kIOReturnError;
#else
    IOSurfaceAcceleratorReturn transferSurfaceResult =
    IOSurfaceAcceleratorTransferSurface(_surfaceAccelerator,
                                        _screenSurface,
                                        _copySurface,
                                        NULL,
                                        NULL);
#endif
    if (transferSurfaceResult != kIOSurfaceAcceleratorSuccess) {
        NSLog(@"failed to copy screen surface");
        return NO;
    }
    return YES;
}

- (BOOL)getScreenSurface {
    char const * const __unused ServiceNames[] = {
        "AppleMobileCLCD",
        "AppleCLCD",
        "AppleH1CLCD",
        "AppleM2CLCD"
    };
    
    IOMobileFramebufferService framebufferService = 0;
#if !TARGET_IPHONE_SIMULATOR
    for (unsigned long i = 0; i < sizeof(ServiceNames) / sizeof(ServiceNames[0]); i++) {

        framebufferService = IOServiceGetMatchingService(kIOMasterPortDefault,
                                                         IOServiceMatching(ServiceNames[i]));
        if (framebufferService) {
            break;
        }
    }
#endif
    if (!framebufferService) {
        NSLog(@"failed to create framebuffer service");
        return NO;
    }
    
    IOMobileFramebufferConnection __unused framebufferConnection = NULL;
#if TARGET_IPHONE_SIMULATOR    
    kern_return_t result = KERN_FAILURE;
#else
    kern_return_t result = IOMobileFramebufferOpen(framebufferService,
                                                   mach_task_self(),
                                                   0,
                                                   &framebufferConnection);
#endif
    if (result != KERN_SUCCESS) {
        NSLog(@"failed to open framebuffer");
        return NO;
    }
    CoreSurfaceBufferRef screenSurface = NULL;
    
#if TARGET_IPHONE_SIMULATOR
    kern_return_t getLayerResult = KERN_FAILURE;
#else
    kern_return_t getLayerResult = IOMobileFramebufferGetLayerDefaultSurface(framebufferConnection,
                                                                             0,
                                                                             &screenSurface);
#endif
    if (getLayerResult != KERN_SUCCESS) {
        NSLog(@"failed to get screen surface");
        return NO;
    }
    
    // CoreSurfaceRef and IOSurfaceRef are toll-free bridged
    _screenSurface = (IOSurfaceRef)screenSurface;
    
    // TODO: Close framebuffer connection?
    // IOMobileFramebufferConnection appears to be a pointer type
    // (it's being dereferenced in IOMobileFramebufferGetLayerDefaultSurface())
    // so it's a different type than io_connect_t,
    // hence we cannot IOServiceClose() it.
    return YES;
}

- (BOOL)createSurfaceAccelerator {
#if TARGET_IPHONE_SIMULATOR
    IOSurfaceAcceleratorReturn result = kIOReturnError;
#else
    IOSurfaceAcceleratorReturn result = IOSurfaceAcceleratorCreate(kCFAllocatorDefault,
                                                                   0,
                                                                   &_surfaceAccelerator);
#endif
    if (result != kIOSurfaceAcceleratorSuccess) {
        NSLog(@"failed to create surface accelerator");
        return NO;
    }
    return YES;
}

- (void)releaseSurfaceAccelerator {
    if (_surfaceAccelerator) {
        CFRelease(_surfaceAccelerator);
        _surfaceAccelerator = NULL;
    }
}

- (BOOL)recreatePixelBufferAndCopySurface {
    CVReturn pixelBufferCreationResult = kCVReturnError;
#if !TARGET_IPHONE_SIMULATOR
    if (_lastRecordingSettings.shouldUseVerticalSynchronization) {
        // If Vsync is important, create a pixel buffer backed by an IOSurface instance.
        // When capturing video, IOSurfaceAccelerator will transfer screen surface contents
        // to this surface, without screen tearing artefacts.
        
        pixelBufferCreationResult = CVPixelBufferCreate(kCFAllocatorDefault,
                                                        IOSurfaceGetWidth(_screenSurface),
                                                        IOSurfaceGetHeight(_screenSurface),
                                                        IOSurfaceGetPixelFormat(_screenSurface),
                                                        (__bridge CFDictionaryRef)@{(__bridge NSString *)kCVPixelBufferIOSurfacePropertiesKey : @{}},
                                                        &_pixelBuffer);
    }
    else {
        // If Vsync is not required, then simply make a new pixel buffer object
        // point to existing pixel data of the screen surface.
        // When capturing video, no pixel data copies will be made at all,
        // but at the cost of sceen tearing in the resulting video file,
        // as captures are not synchronized precisely with screen refresh rate.
        pixelBufferCreationResult = CVPixelBufferCreateWithBytes(kCFAllocatorDefault,
                                                                 IOSurfaceGetWidth(_screenSurface),
                                                                 IOSurfaceGetHeight(_screenSurface),
                                                                 IOSurfaceGetPixelFormat(_screenSurface),
                                                                 IOSurfaceGetBaseAddress(_screenSurface),
                                                                 IOSurfaceGetBytesPerRow(_screenSurface),
                                                                 NULL,
                                                                 NULL,
                                                                 (__bridge CFDictionaryRef)@{},
                                                                 &_pixelBuffer);
    }
#endif
    
    if (pixelBufferCreationResult != kCVReturnSuccess) {
        NSLog(@"failed to create pixel buffer");
        return NO;
    }
    
    if (_lastRecordingSettings.shouldUseVerticalSynchronization) {
#if TARGET_IPHONE_SIMULATOR
        _copySurface = NULL;
#else
        _copySurface = CVPixelBufferGetIOSurface(_pixelBuffer);
#endif
        if (_copySurface == NULL) {
            NSLog(@"failed to get surface from pixel buffer");
            return NO;
        }
    }
    
    return YES;
}

- (void)releasePixelBuffer {
    CVPixelBufferRelease(_pixelBuffer);
    _pixelBuffer = NULL;
    _copySurface = NULL;
}

- (BOOL)recreateVideoWriter {
    NSError * __autoreleasing error;
    
    _videoWriter = [[AVAssetWriter alloc] initWithURL:_lastRecordingVideoFileURL
                                             fileType:AVFileTypeMPEG4
                                                error:&error];
    if (!_videoWriter) {
        NSLog(@"error creating an AVAssetWriter: %@", error);
        return NO;
    }
    return YES;
}

- (void)releaseVideoWriter {
    _videoWriter = nil;
}

- (void)recreateBackgroundRunloop {
    _backgroundRunloop = [SGVBackgroundRunloop new];
}

- (void)shutdownBackgroundRunloop {
    _backgroundRunloop = nil;
}

- (void)recreateDisplayLink {
    __typeof(self) __weak wself = self;
    [_backgroundRunloop performBlock:^{
        __typeof(self) sself = wself;
        if (sself) {
            sself->_displayLink = [CADisplayLink displayLinkWithTarget:self
                                                              selector:@selector(displayLinkFired:)];
            [sself->_displayLink addToRunLoop:[NSRunLoop currentRunLoop]
                                      forMode:NSRunLoopCommonModes];
        }
    }];
}

- (void)shutdownDisplayLink {
    __typeof(self) __weak wself = self;
    [_backgroundRunloop performBlock:^{
        __typeof(self) sself = wself;
        if (sself) {
            [sself->_displayLink invalidate];
            sself->_displayLink = nil;
        }
    }];
}

- (NSDictionary *)outputSettingsForVideoWriter {
    
    NSCAssert(_screenSurface, @"_screenSurface must not be NULL");

    NSUInteger outputWidth = 0;
    NSUInteger outputHeight = 0;
#if !TARGET_IPHONE_SIMULATOR
    outputWidth = IOSurfaceGetWidth(_screenSurface);
    outputHeight = IOSurfaceGetHeight(_screenSurface);
#endif
    
    if (outputWidth > outputHeight) {
        if (outputWidth > _lastRecordingSettings.maximumVideoDimension) {
            double heightToWidthRatio = (double)outputHeight / (double)outputWidth;
            outputWidth = _lastRecordingSettings.maximumVideoDimension;
            outputHeight = (NSUInteger)round(outputWidth * heightToWidthRatio);
        }
    }
    else {
        if (outputHeight > _lastRecordingSettings.maximumVideoDimension) {
            double widthToHeightRatio = (double)outputWidth / (double)outputHeight;
            outputHeight = _lastRecordingSettings.maximumVideoDimension;
            outputWidth = (NSUInteger)round(outputHeight * widthToHeightRatio);
        }
    }
    
    NSMutableDictionary *settingsDictionary = [@{
        AVVideoCodecKey                 : AVVideoCodecH264,
        AVVideoWidthKey                 : @(outputWidth),
        AVVideoHeightKey                : @(outputHeight),
    } mutableCopy];
    settingsDictionary[AVVideoCompressionPropertiesKey] = _lastRecordingSettings.videoCompressionProperties;
    return settingsDictionary;
}

- (BOOL)recreateVideoWriterInputAndPixelBufferAdaptor {
    
    NSCAssert(_videoWriter, @"_videoWriter must not be nil");
    
    NSDictionary *outputSettings = [self outputSettingsForVideoWriter];
    
    if (![_videoWriter canApplyOutputSettings:outputSettings
                                 forMediaType:AVMediaTypeVideo]) {
        NSLog(@"video writer cannot apply output settings");
        return NO;
    }
    
    NSCAssert(_pixelBuffer, @"_copySurfacePixelBuffer must not be NULL");
    
    CMVideoFormatDescriptionRef videoFormatDescription = NULL;
    OSStatus formatDescriptionResult = CMVideoFormatDescriptionCreateForImageBuffer(kCFAllocatorDefault,
                                                                                    _pixelBuffer,
                                                                                    &videoFormatDescription);
    if (formatDescriptionResult != noErr) {
        NSLog(@"falied to create video format description");
        return NO;
    }
    
    AVAssetWriterInput *videoWriterInput = [AVAssetWriterInput assetWriterInputWithMediaType:AVMediaTypeVideo
                                                                              outputSettings:outputSettings
                                                                            sourceFormatHint:videoFormatDescription];
    CFRelease(videoFormatDescription);
    videoWriterInput.expectsMediaDataInRealTime = YES;
    videoWriterInput.mediaTimeScale = (CMTimeScale)_lastRecordingSettings.framesPerSecond;
    
    if (![_videoWriter canAddInput:videoWriterInput]) {
        NSLog(@"unable to add input to video writer");
        return NO;
    }
    [_videoWriter addInput:videoWriterInput];
    
    _pixelBufferAdaptor = [AVAssetWriterInputPixelBufferAdaptor assetWriterInputPixelBufferAdaptorWithAssetWriterInput:videoWriterInput
                                                                                           sourcePixelBufferAttributes:nil];
    
    return YES;
}

- (void)releasePixelBufferAdaptor {
    _pixelBufferAdaptor = nil;
}

- (BOOL)startWriting {
    NSCAssert(_videoWriter, @"_videoWriter must not be nil");
    BOOL startWritingResult = [_videoWriter startWriting];
    if (!startWritingResult) {
        NSLog(@"failed to start writing video: %@", _videoWriter.error);
        return NO;
    }
    return YES;
}

- (void)startSessionAtCurrentMediaTime {
    _lastFrameTime = CMTimeMakeWithSeconds(CACurrentMediaTime(),
                                           (int32_t)_lastRecordingSettings.framesPerSecond);
    [_videoWriter startSessionAtSourceTime:_lastFrameTime];
}

- (void)finishWritingWithCompletion:(void(^)(void))completion {
    [_videoWriter finishWritingWithCompletionHandler:completion];
}

@end
