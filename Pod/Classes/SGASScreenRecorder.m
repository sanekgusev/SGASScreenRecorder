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

static NSInteger const kDisplayLinkFrameRate = 60;

typedef struct PixelSize {
    NSUInteger width;
    NSUInteger height;
} PixelSize;

#pragma mark - Private Declarations
extern IOSurfaceRef CVPixelBufferGetIOSurface(CVPixelBufferRef pixelBuffer);

@interface SGASScreenRecorder () {
    AVAssetWriter *_videoWriter;
    AVAssetWriterInputPixelBufferAdaptor *_pixelBufferAdaptor;
    
    SGVBackgroundRunloop *_backgroundRunloop;
    CADisplayLink *_displayLink;
    CMTime _lastFrameTime;
    
    id _applicationDidEnterBackgroundObserver;
    
    IOMobileFramebufferConnection _framebufferConnection;
    IOSurfaceAcceleratorRef _surfaceAccelerator;
    
    IOSurfaceRef _screenSurface;
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
        if (![self createFramebufferConnection] || ![self getScreenSurface] ||
            ![self createSurfaceAccelerator]) {
            return nil;
        }
        [self subscribeForEnterBackgroundNotification];
    }
    return self;
}

- (void)dealloc {
    [self destroySurfaceAccelerator];
    [self destroyFramebufferConnection];
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
    
    if (![self recreateVideoWriter]) {
        return;
    }

    if (![self configureVideoWriterInput]) {
        return;
    }
    
    [self recreateBackgroundRunloop];
    __typeof(self) __weak wself = self;
    [_backgroundRunloop performBlock:^{
        [wself startEncoding];
    }];
    [self recreateDisplayLink];
}

- (void)stopRecording {
    if (!self.recording) {
        return;
    }

    [self shutdownDisplayLink];
    __typeof(self) __weak wself = self;
    [_backgroundRunloop performBlock:^{
        [wself finishEncoding];
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

#pragma mark - Capturing

- (void)captureScreenshot {
    if (!_pixelBufferAdaptor.assetWriterInput.readyForMoreMediaData) {
        NSLog(@"asset writer input not ready for media data");
        return;
    }
    
    if (_pixelBufferAdaptor.pixelBufferPool == NULL) {
        NSLog(@"pixel buffer pool is null");
        return;
    }
    CVPixelBufferRef pixelBuffer = NULL;
    CVReturn pixelBufferCreationResult = CVPixelBufferPoolCreatePixelBuffer(kCFAllocatorDefault,
                                                                            _pixelBufferAdaptor.pixelBufferPool,
                                                                            &pixelBuffer);
    if (pixelBufferCreationResult != kCVReturnSuccess) {
        NSLog(@"failed to create a pixel buffer from pixel buffer pool");
        return;
    }
    pixelBuffer = (CVPixelBufferRef)CFAutorelease(pixelBuffer);
#if TARGET_IPHONE_SIMULATOR
    IOSurfaceRef surface = NULL;
#else
    IOSurfaceRef surface = CVPixelBufferGetIOSurface(pixelBuffer);
#endif
    if (surface == NULL) {
        NSLog(@"failed to get surface from pixel buffer");
        return;
    }
    
    CMTime frameTime = CMTimeMakeWithSeconds(_displayLink.timestamp,
                                             (int32_t)_lastRecordingSettings.framesPerSecond);
    // Pixel buffer adapter becomes upset once one tries to feed it with a new
    // pixel buffer having the same presentation time as the previous one
    // (which makes sense), so we need to keep track of the previous presentation time.
    if (CMTimeCompare(_lastFrameTime, frameTime) >= 0) {
        // But we don't want to drop a frame too, so if we know that our framerate
        // is equal or above that of displaylink (60fps) then we'll assume
        // that this is the result of a rounding error and will increment
        // previous presentation time by one ourselves to avoid dropping the frame
        if (_lastRecordingSettings.framesPerSecond >= kDisplayLinkFrameRate) {
            frameTime = CMTimeAdd(_lastFrameTime, CMTimeMake(1, frameTime.timescale));
            NSLog(@"new presentation time is less than or equal to previous,"
                  @"incrementing it manually");
        }
        else {
            NSLog(@"new presentation time is less than or equal to previous,"
                  @"dropping this frame");
            return;
        }
    }
    _lastFrameTime = frameTime;
    
#if TARGET_IPHONE_SIMULATOR
    IOSurfaceAcceleratorReturn transferSurfaceResult = kIOReturnError;
#else
    IOSurfaceAcceleratorReturn transferSurfaceResult =
        IOSurfaceAcceleratorTransferSurface(_surfaceAccelerator,
                                            _screenSurface,
                                            surface,
                                            NULL,
                                            NULL);
#endif
    if (transferSurfaceResult != kIOSurfaceAcceleratorSuccess) {
        NSLog(@"failed to copy screen surface");
        return;
    }
    
    BOOL pixelBufferAppendResult = [_pixelBufferAdaptor appendPixelBuffer:pixelBuffer
                                                     withPresentationTime:frameTime];
    if (!pixelBufferAppendResult) {
        NSLog(@"failed to append pixel buffer");
    }
}

#pragma mark - Encoding

- (BOOL)createFramebufferConnection {
#if TARGET_IPHONE_SIMULATOR
    return NO;
#else
    static char const * const ServiceNames[] = {"AppleH1CLCD", "AppleM2CLCD", "AppleCLCD", "AppleMobileCLCD"};
    IOMobileFramebufferService framebufferService = 0;
    for (unsigned long i = 0; i < sizeof(ServiceNames) / sizeof(ServiceNames[0]); i++) {
        framebufferService = IOServiceGetMatchingService(kIOMasterPortDefault, IOServiceMatching(ServiceNames[i]));
        if (framebufferService) {
            break;
        }
    }
    if (!framebufferService) {
        NSLog(@"failed to create framebuffer service");
        return NO;
    }
    
    kern_return_t result = IOMobileFramebufferOpen(framebufferService, mach_task_self(), 0, &_framebufferConnection);
    if (result != KERN_SUCCESS) {
        NSLog(@"failed to open framebuffer");
        return NO;
    }
    return YES;
#endif
}

- (void)destroyFramebufferConnection {
#if !TARGET_IPHONE_SIMULATOR
    // TODO: This is a very suspicious cast.
    // IOMobileFramebufferConnection appears to be a pointer type
    // (it's being dereferenced in IOMobileFramebufferGetLayerDefaultSurface)
    // so it's (generally) wider that io_connect_t, which is unsigned int
    IOServiceClose((io_connect_t)_framebufferConnection);
    _framebufferConnection = 0;
#endif
}

- (BOOL)getScreenSurface {
    CoreSurfaceBufferRef screenSurface = NULL;
    
#if TARGET_IPHONE_SIMULATOR
    kern_return_t getLayerResult = KERN_FAILURE;
#else
    kern_return_t getLayerResult = IOMobileFramebufferGetLayerDefaultSurface(_framebufferConnection, 0, &screenSurface);
#endif
    if (getLayerResult != KERN_SUCCESS) {
        NSLog(@"failed to get screen surface");
        return NO;
    }
    
    _screenSurface = (IOSurfaceRef)screenSurface;
    return YES;
}

- (BOOL)createSurfaceAccelerator {
#if TARGET_IPHONE_SIMULATOR
    return NO;
#else
    IOSurfaceAcceleratorReturn result = IOSurfaceAcceleratorCreate(kCFAllocatorDefault, 0, &_surfaceAccelerator);
    if (result != kIOSurfaceAcceleratorSuccess) {
        NSLog(@"failed to create surface accelerator");
        return NO;
    }
    return YES;
#endif
}

- (void)destroySurfaceAccelerator {
    if (_surfaceAccelerator) {
        CFRelease(_surfaceAccelerator);
        _surfaceAccelerator = NULL;
    }
}

- (PixelSize)screenPixelSize {
#if TARGET_IPHONE_SIMULATOR
    return (PixelSize){0,0};
#else
    size_t width = IOSurfaceGetWidth(_screenSurface);
    size_t height = IOSurfaceGetHeight(_screenSurface);
    return (PixelSize){width, height};
#endif
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
            sself->_displayLink = [[UIScreen mainScreen] displayLinkWithTarget:self
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

- (NSDictionary *)outputSettingsForVideoWriterWithScreenPixelSize:(PixelSize)screenPixelSize {

    NSUInteger outputWidth = screenPixelSize.width;
    NSUInteger outputHeight = screenPixelSize.height;
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

- (BOOL)configureVideoWriterInput {
    
    NSCAssert(_videoWriter, @"_videoWriter must not be nil");
    
    PixelSize screenPixelSize = [self screenPixelSize];
    
    NSDictionary *outputSettings = [self outputSettingsForVideoWriterWithScreenPixelSize:screenPixelSize];
    
    if (![_videoWriter canApplyOutputSettings:outputSettings
                                 forMediaType:AVMediaTypeVideo]) {
        NSLog(@"video writer cannot apply output settings");
        return NO;
    }
    
    AVAssetWriterInput *videoWriterInput = [AVAssetWriterInput assetWriterInputWithMediaType:AVMediaTypeVideo
                                                                              outputSettings:outputSettings];
    videoWriterInput.expectsMediaDataInRealTime = YES;
    
    if (![_videoWriter canAddInput:videoWriterInput]) {
        NSLog(@"unable to add input to video writer");
        return NO;
    }
    [_videoWriter addInput:videoWriterInput];
    
    // kCVPixelBufferIOSurfacePropertiesKey is specified to make pixel buffer pool vend us
    // IOSurface-backed pixel buffers. This way, we can use fast IOSurfaceAccelerator
    // functions to copy screen IOSurface to the internal IOSurface of our pixel buffers
    NSDictionary *bufferAttributes = @{
        (__bridge NSString *)kCVPixelBufferPixelFormatTypeKey : @(kCVPixelFormatType_32BGRA),
        (__bridge NSString *)kCVPixelBufferWidthKey           : @(screenPixelSize.width),
        (__bridge NSString *)kCVPixelBufferHeightKey          : @(screenPixelSize.height),
        (__bridge NSString *)kCVPixelBufferIOSurfacePropertiesKey : @{},
    };
    
    // Get AVAssetWriterInputPixelBufferAdaptor with the buffer attributes
    _pixelBufferAdaptor = [AVAssetWriterInputPixelBufferAdaptor assetWriterInputPixelBufferAdaptorWithAssetWriterInput:videoWriterInput
                                                                                           sourcePixelBufferAttributes:bufferAttributes];
    
    BOOL startWritingResult = [_videoWriter startWriting];
    if (!startWritingResult) {
        NSLog(@"failed to start writing video: %@", _videoWriter.error);
        return NO;
    }
    return YES;
}

- (void)startEncoding {
    _lastFrameTime = CMTimeMakeWithSeconds(CACurrentMediaTime(),
                                           (int32_t)_lastRecordingSettings.framesPerSecond);
    [_videoWriter startSessionAtSourceTime:_lastFrameTime];
}

- (void)finishEncoding {
    [_videoWriter.inputs.firstObject markAsFinished];
    // Tell the AVAssetWriter to finish and close the file
    __typeof(self) __weak wself = self;
    [_videoWriter finishWritingWithCompletionHandler:^{

        __typeof(self) sself = wself;
        if (sself) {
            sself->_videoWriter = nil;
            sself->_pixelBufferAdaptor = nil;
            
            if (sself->_completionBlock) {
                sself->_completionBlock(sself->_lastRecordingVideoFileURL);
            }
        }
    }];
}

@end
