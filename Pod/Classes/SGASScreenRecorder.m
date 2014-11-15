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
    NSTimeInterval _initialTimestamp;
    CMTime _lastFrameTime;
    
    dispatch_group_t _captureDispatchGroup;
    dispatch_queue_t _captureDispatchQueue;
    
    id _applicationDidEnterBackgroundObserver;
    
    IOMobileFramebufferConnection _framebufferConnection;
    IOSurfaceAcceleratorRef _surfaceAccelerator;
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
        if (![self createFramebufferConnection] || ![self createSurfaceAccelerator]) {
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
    _initialTimestamp = [NSDate timeIntervalSinceReferenceDate];
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
                             [wself captureScreenshot];
                         });
}

#pragma mark - Capturing

- (void)captureScreenshot {
    if (!_pixelBufferAdaptor.assetWriterInput.readyForMoreMediaData) {
        NSLog(@"not ready for more data");
        return;
    }
    
    if (!_pixelBufferAdaptor.pixelBufferPool) {
        return;
    }
    CVPixelBufferRef pixelBuffer = NULL;
    CVReturn pixelBufferCreationResult = CVPixelBufferPoolCreatePixelBuffer(kCFAllocatorDefault, _pixelBufferAdaptor.pixelBufferPool, &pixelBuffer);
    if (pixelBufferCreationResult != kCVReturnSuccess) {
        return;
    }
#if TARGET_IPHONE_SIMULATOR
    IOSurfaceRef surface = NULL;
#else
    IOSurfaceRef surface = CVPixelBufferGetIOSurface(pixelBuffer);
#endif
    if (surface == NULL) {
        CVPixelBufferRelease(pixelBuffer);
        return;
    }
    
    NSTimeInterval frameTimestamp = [NSDate timeIntervalSinceReferenceDate] - _initialTimestamp;
    CMTime frameTime = CMTimeMakeWithSeconds(frameTimestamp, (int32_t)_settings.framesPerSecond);
    if (CMTimeCompare(_lastFrameTime, frameTime) == 0) {
        NSLog(@"same frame times!");
        CVPixelBufferRelease(pixelBuffer);
        return;
    }
    _lastFrameTime = frameTime;
    // Take currently displayed image from the LCD
//    IOSurfaceLock(surface, 0, NULL);
    
//    IOMobileFramebufferConnection connect;
    CoreSurfaceBufferRef __unused screenSurface = NULL;
    
//    io_service_t framebufferService = IOServiceGetMatchingService(kIOMasterPortDefault, IOServiceMatching("AppleH1CLCD"));
//    if(!framebufferService)
//        framebufferService = IOServiceGetMatchingService(kIOMasterPortDefault, IOServiceMatching("AppleM2CLCD"));
//    if(!framebufferService)
//        framebufferService = IOServiceGetMatchingService(kIOMasterPortDefault, IOServiceMatching("AppleCLCD"));
    
//    result = IOMobileFramebufferOpen(framebufferService, mach_task_self(), 0, &connect);
    
#if TARGET_IPHONE_SIMULATOR
    kern_return_t getLayerResult = KERN_FAILURE;
#else
    kern_return_t getLayerResult = IOMobileFramebufferGetLayerDefaultSurface(_framebufferConnection, 0, &screenSurface);
#endif
    if (getLayerResult != KERN_SUCCESS) {
        CVPixelBufferRelease(pixelBuffer);
        return;
    }
    
//    uint32_t aseed;
//    IOSurfaceLock(screenSurface, kIOSurfaceLockReadOnly, &aseed);
    
//    IOSurfaceAcceleratorRef outAcc;
//    IOSurfaceAcceleratorCreate(NULL, 0, &outAcc);
#if TARGET_IPHONE_SIMULATOR
    IOSurfaceAcceleratorReturn transferSurfaceResult = kIOReturnError;
#else
    IOSurfaceAcceleratorReturn transferSurfaceResult = IOSurfaceAcceleratorTransferSurface(_surfaceAccelerator, (IOSurfaceRef)screenSurface, surface, NULL, NULL);
#endif
    if (transferSurfaceResult != kIOSurfaceAcceleratorSuccess) {
        CVPixelBufferRelease(pixelBuffer);
        return;
    }
    
//    IOSurfaceUnlock(screenSurface, kIOSurfaceLockReadOnly, &aseed);
    
//    CFRelease(outAcc);
//    IOSurfaceUnlock(surface, 0, NULL);
    
    BOOL pixelBufferAppendResult = [_pixelBufferAdaptor appendPixelBuffer:pixelBuffer
                                                     withPresentationTime:frameTime];
    CVPixelBufferRelease(pixelBuffer);
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
    
    kern_return_t result = IOMobileFramebufferOpen(framebufferService, mach_task_self(), 0, &_framebufferConnection);
    return result == KERN_SUCCESS;
#endif
}

- (void)destroyFramebufferConnection {
#if !TARGET_IPHONE_SIMULATOR
    IOServiceClose(_framebufferConnection);
    _framebufferConnection = 0;
#endif
}

- (BOOL)createSurfaceAccelerator {
#if TARGET_IPHONE_SIMULATOR
    return NO;
#else
    return IOSurfaceAcceleratorCreate(kCFAllocatorDefault, 0, &_surfaceAccelerator) == kIOSurfaceAcceleratorSuccess;
#endif
}

- (void)destroySurfaceAccelerator {
    if (_surfaceAccelerator) {
        CFRelease(_surfaceAccelerator);
        _surfaceAccelerator = NULL;
    }
}

- (CGSize)frameBufferSize {
    // FIXME: use a more consistent approach
    if (NSFoundationVersionNumber > NSFoundationVersionNumber_iOS_7_1) {
        return [[UIScreen mainScreen] nativeBounds].size;
    }
    CGFloat scale = [UIScreen mainScreen].scale;
    return CGSizeApplyAffineTransform([UIScreen mainScreen].bounds.size,
                                            CGAffineTransformMakeScale(scale, scale));
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
            sself->_displayLink = [CADisplayLink displayLinkWithTarget:sself
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

- (NSDictionary *)outputSettingsForVideoWriterWithFramebufferSize:(CGSize)framebufferSize {
    
    // Setup output settings, Codec, Width, Height, Compression
    NSInteger videowidth = (NSInteger)round(framebufferSize.width * _settings.outputSizeRatio);
    NSInteger videoheight = (NSInteger)round(framebufferSize.height * _settings.outputSizeRatio);

    return @{
        AVVideoCodecKey                 : AVVideoCodecH264,
        AVVideoWidthKey                 : @(videowidth),
        AVVideoHeightKey                : @(videoheight),
        AVVideoCompressionPropertiesKey : _settings.compressionSettings,
    };
}

- (void)setupVideoContext {
    
    CGSize framebufferSize = [self frameBufferSize];
    
    if (![self setupVideoWriter]) {
        return;
    }
    
    // Makes sure AVAssetWriter is valid (check check check)
    NSCAssert(_videoWriter, @"_videoWriter should be created");
    
    NSDictionary *outputSettings = [self outputSettingsForVideoWriterWithFramebufferSize:framebufferSize];
    
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
        (id)kCVPixelBufferWidthKey           : @(framebufferSize.width),
        (id)kCVPixelBufferHeightKey          : @(framebufferSize.height),
        (id)kCVPixelBufferIOSurfacePropertiesKey : @{},
    };
    
    // Get AVAssetWriterInputPixelBufferAdaptor with the buffer attributes
    _pixelBufferAdaptor = [AVAssetWriterInputPixelBufferAdaptor assetWriterInputPixelBufferAdaptorWithAssetWriterInput:videoWriterInput
                                                                                           sourcePixelBufferAttributes:bufferAttributes];

    //Start a session:
    [videoWriterInput setExpectsMediaDataInRealTime:YES];
    [_videoWriter startWriting];
    [_videoWriter startSessionAtSourceTime:kCMTimeZero];
    
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
