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
    
    dispatch_group_t _captureDispatchGroup;
    dispatch_queue_t _captureDispatchQueue;
    
    id _applicationDidEnterBackgroundObserver;
    
    IOMobileFramebufferConnection _framebufferConnection;
    IOSurfaceAcceleratorRef _surfaceAccelerator;
    
    IOSurfaceRef _screenSurface;
}

@end

@implementation SGASScreenRecorder

@dynamic recording;

#pragma mark - Init/dealloc
- (instancetype)initWithSettings:(SGASScreenRecorderSettings *)settings {
    NSCParameterAssert(settings);
    if (!settings) {
        return nil;
    }
    if (![SGASScreenRecorder isSupported]) {
        return nil;
    }
    self = [super init];
    if (self) {
        _settings = settings;
        if (![self createFramebufferConnection] || ![self getScreenSurface] || ![self createSurfaceAccelerator]) {
            return nil;
        }
        [self setupDispatchGroup];
        [self createDispatchQueue];
    }
    return self;
}

- (instancetype)init {
    return [self initWithSettings:[SGASScreenRecorderSettings new]];
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

+ (instancetype)defaultRecorder {
    static dispatch_once_t onceToken;
    static SGASScreenRecorder *defaultRecorder = nil;
    dispatch_once(&onceToken, ^{
        defaultRecorder = [SGASScreenRecorder new];
    });
    return defaultRecorder;
}

- (void)startRecordingToFileAtURL:(NSURL *)videoFileURL {
    NSCParameterAssert([videoFileURL isFileURL]);
    if (![videoFileURL isFileURL]) {
        return;
    }
    NSCAssert(!self.recording, @"Already recording.");
    if (self.recording) {
        return;
    }
    _lastRecordedVideoFileURL = videoFileURL;

    [self setupVideoContext];
    
    [self recreateBackgroundRunloop];
    [self recreateDisplayLink];
    _lastFrameTime = kCMTimeZero;
}

- (void)stopRecording {
    if (!self.recording) {
        return;
    }

    [self shutdownDisplayLink];
    [self shutdownBackgroundRunloop];
    
    dispatch_group_notify(_captureDispatchGroup,
                          _captureDispatchQueue, ^{
        [self finishEncoding];
    });
}

#pragma mark - Properties

- (BOOL)isRecording {
    return !!_videoWriter;
}

- (void)setShouldStopRecordingWhenMovingToBackground:(BOOL)shouldStopRecordingWhenMovingToBackground {
    if (_shouldStopRecordingWhenMovingToBackground != !!shouldStopRecordingWhenMovingToBackground) {
        _shouldStopRecordingWhenMovingToBackground = !!shouldStopRecordingWhenMovingToBackground;
        if (_shouldStopRecordingWhenMovingToBackground) {
            [self subscribeForEnterBackgroundNotification];
        }
        else {
            [self unsubscribeFromEnterBackgroundNotification];
        }
    }
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
    if (dispatch_group_wait(_captureDispatchGroup, DISPATCH_TIME_NOW) != 0) {
        NSLog(@"capture queue busy");
        return;
    }
    __typeof(self) __weak wself = self;
    dispatch_group_async(_captureDispatchGroup,
                         _captureDispatchQueue,
                         ^{
                             @autoreleasepool {
                                 [wself captureScreenshot];
                             }
                         });
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
    
    CMTime frameTime = CMTimeMakeWithSeconds([NSDate timeIntervalSinceReferenceDate],
                                             (int32_t)_settings.framesPerSecond);
    if (CMTimeCompare(_lastFrameTime, frameTime) == 0) {
        NSLog(@"new frame presentation time equals presentation frame for previous frame");
        return;
    }
    _lastFrameTime = frameTime;
    
//    uint32_t lockSeed;
//    IOReturn lockResult = IOSurfaceLock(_screenSurface, kIOSurfaceLockReadOnly, &lockSeed);
//    if (lockResult != kIOReturnSuccess) {
//        NSLog(@"failed to lock screen surface: %d", lockResult);
//    }
    
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
    
//    uint32_t unlockSeed;
//    IOReturn unlockResult = IOSurfaceUnlock(_screenSurface, kIOSurfaceLockReadOnly, &unlockSeed);
//    if (unlockResult != kIOReturnSuccess) {
//        NSLog(@"failed to unlock screen surface: %d", unlockResult);
//    }
//    if (unlockSeed != lockSeed) {
//        NSLog(@"seeds for screen surface do not match — surface has been modified during copy");
//        return;
//    }
    
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
    io_service_t framebufferService = IOServiceGetMatchingService(kIOMasterPortDefault, IOServiceMatching("AppleH1CLCD"));
    if (!framebufferService) {
        framebufferService = IOServiceGetMatchingService(kIOMasterPortDefault, IOServiceMatching("AppleM2CLCD"));
    }
    if (!framebufferService) {
        framebufferService = IOServiceGetMatchingService(kIOMasterPortDefault, IOServiceMatching("AppleCLCD"));
    }
    if (!framebufferService) {
        framebufferService = IOServiceGetMatchingService(kIOMasterPortDefault, IOServiceMatching("AppleMobileCLCD"));
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
    IOSurfaceRef screenSurface = NULL;
    kern_return_t getLayerResult = IOMobileFramebufferGetLayerDefaultSurface(_framebufferConnection,
                                                                             0,
                                                                             (CoreSurfaceBufferRef *)&screenSurface);
    if (getLayerResult != KERN_SUCCESS) {
        NSLog(@"failed to get default surface");
        return (PixelSize){0, 0};
    }
    size_t width = IOSurfaceGetWidth(screenSurface);
    size_t height = IOSurfaceGetHeight(screenSurface);
    return (PixelSize){width, height};
#endif
}

- (BOOL)setupVideoWriter {
    NSError * __autoreleasing error;
    
    _videoWriter = [[AVAssetWriter alloc] initWithURL:_lastRecordedVideoFileURL
                                             fileType:AVFileTypeMPEG4
                                                error:&error];
    if (!_videoWriter) {
        NSLog(@"error careting an AVAssetWriter: %@", error);
        return NO;
    }
    return YES;
}

- (void)setupDispatchGroup {
    _captureDispatchGroup = dispatch_group_create();
}

- (void)createDispatchQueue {
    _captureDispatchQueue = dispatch_queue_create(NULL, DISPATCH_QUEUE_CONCURRENT);
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
    
    // Setup output settings, Codec, Width, Height, Compression
    NSUInteger outputWidth = screenPixelSize.width;
    NSUInteger outputHeight = screenPixelSize.height;
    if (outputWidth > outputHeight) {
        if (outputWidth > _settings.maximumOutputVideoDimension) {
            double heightToWidthRatio = (double)outputHeight / (double)outputWidth;
            outputWidth = _settings.maximumOutputVideoDimension;
            outputHeight = (NSUInteger)round(outputWidth * heightToWidthRatio);
        }
    }
    else {
        if (outputHeight > _settings.maximumOutputVideoDimension) {
            double widthToHeightRatio = (double)outputWidth / (double)outputHeight;
            outputHeight = _settings.maximumOutputVideoDimension;
            outputWidth = (NSUInteger)round(outputHeight * widthToHeightRatio);
        }
    }

    return @{
        AVVideoCodecKey                 : AVVideoCodecH264,
        AVVideoWidthKey                 : @(outputWidth),
        AVVideoHeightKey                : @(outputHeight),
        AVVideoCompressionPropertiesKey : _settings.compressionSettings,
    };
}

- (void)setupVideoContext {
    
    PixelSize screenPixelSize = [self screenPixelSize];
    
    if (![self setupVideoWriter]) {
        return;
    }
    
    // Makes sure AVAssetWriter is valid (check check check)
    NSCAssert(_videoWriter, @"_videoWriter should be created");
    
    NSDictionary *outputSettings = [self outputSettingsForVideoWriterWithScreenPixelSize:screenPixelSize];
    
    NSCAssert([_videoWriter canApplyOutputSettings:outputSettings
                                      forMediaType:AVMediaTypeVideo],
              @"cannot apply output settings");
    
    // Get a AVAssetWriterInput
    // Add the output settings
    AVAssetWriterInput *videoWriterInput = [AVAssetWriterInput assetWriterInputWithMediaType:AVMediaTypeVideo
                                                                              outputSettings:outputSettings];
    
    // Check if AVAssetWriter will take an AVAssetWriterInput
    NSCAssert(videoWriterInput, @"videoWriterInput should be created");
    NSCAssert([_videoWriter canAddInput:videoWriterInput], @"unable to add input to video writer");
    [_videoWriter addInput:videoWriterInput];
    
    // Setup buffer attributes, PixelFormatType, PixelBufferWidth, PixelBufferHeight, PixelBufferMemoryAlocator
    NSDictionary *bufferAttributes = @{
        (id)kCVPixelBufferPixelFormatTypeKey : @(kCVPixelFormatType_32BGRA),
        (id)kCVPixelBufferWidthKey           : @(screenPixelSize.width),
        (id)kCVPixelBufferHeightKey          : @(screenPixelSize.height),
        (id)kCVPixelBufferIOSurfacePropertiesKey : @{},
    };
    
    // Get AVAssetWriterInputPixelBufferAdaptor with the buffer attributes
    _pixelBufferAdaptor = [AVAssetWriterInputPixelBufferAdaptor assetWriterInputPixelBufferAdaptorWithAssetWriterInput:videoWriterInput
                                                                                           sourcePixelBufferAttributes:bufferAttributes];

    //Start a session:
    [videoWriterInput setExpectsMediaDataInRealTime:YES];
    [_videoWriter startWriting];
    [_videoWriter startSessionAtSourceTime:CMTimeMakeWithSeconds([NSDate timeIntervalSinceReferenceDate],
                                                                 (int32_t)_settings.framesPerSecond)];
    
    NSCAssert(_pixelBufferAdaptor.pixelBufferPool != NULL, @"pixelBufferPool should not be NULL");
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
                sself->_completionBlock(sself->_lastRecordedVideoFileURL);
            }
        }
    }];
}

@end
