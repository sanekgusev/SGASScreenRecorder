//
//  SGASScreenRecorderUIManager.m
//  SGASScreenRecorder
//
//  Created by Aleksandr Gusev on 23/10/14.
//
//

#import "SGASScreenRecorderUIManager.h"
#import "SGASStatusBarOverlayWindow.h"
#import "SGASPhotoLibraryScreenRecorder.h"
#import "SGASTouchVisualizer.h"
#import "NSObject+SGVObjcMixin.h"

NS_ASSUME_NONNULL_BEGIN

static CGSize const kDefaultOverlayWindowSize = (CGSize){20.0f, 20.0f};
static CGSize const kDefaultActivationTapAreaSize = (CGSize){44.0f, 44.0f};

static NSInteger const kNumberOfTaps = 3;
static NSInteger const kNumberOfTouches = 1;

@interface SGASScreenRecorderUIManager ()<UIGestureRecognizerDelegate> {
    
    UIRectCorner _screenCorner;
    CGSize _overlayWindowSize;
    CGSize _activationTapAreaSize;
    SGASScreenRecorderSettings *_screenRecorderSettings;
    
    SGASPhotoLibraryScreenRecorder * _screenRecorder;
    SGASStatusBarOverlayWindow *_overlayWindow;
    UITapGestureRecognizer *_mainWindowTapRecognizer;
    UITapGestureRecognizer *_statusbarWindowTapRecognizer;
    
    id _applicationDidChangeStatusbarOrientationObserver;
    id _windowDidBecomeKeyObserver;
}

@end

@implementation SGASScreenRecorderUIManager

#pragma mark - Init/dealloc

- (instancetype)initWithScreenCorner:(UIRectCorner)screenCorner
                   overlayWindowSize:(CGSize)overlayWindowSize
               activationTapAreaSize:(CGSize)activationTapAreaSize
              screenRecorderSettings:(SGASScreenRecorderSettings *)settings {
    NSCParameterAssert(settings);
    if (!settings) {
        return nil;
    }
    if (self = [super init]) {
        _screenCorner = screenCorner;
        _overlayWindowSize = overlayWindowSize;
        _activationTapAreaSize = activationTapAreaSize;
        _screenRecorderSettings = settings;
    }
    return self;
}

- (instancetype)initWithScreenCorner:(UIRectCorner)screenCorner
              screenRecorderSettings:(SGASScreenRecorderSettings *)settings {
    return [self initWithScreenCorner:screenCorner
            overlayWindowSize:kDefaultOverlayWindowSize
                activationTapAreaSize:kDefaultActivationTapAreaSize
            screenRecorderSettings:settings];
}

- (instancetype)init {
    return [self initWithScreenCorner:UIRectCornerTopRight
               screenRecorderSettings:[SGASScreenRecorderSettings new]];
}

- (void)dealloc {
    [self unsubscribeFromNotifications];
    [self removeTapRecognizers];
}

#pragma mark - Properties

- (void)setEnabled:(BOOL)enabled {
    if (_enabled != !!enabled) {
        _enabled = !!enabled;
        if (_enabled) {
            [self recreateOverlayWindow];
            [self recreateTapRecognizers];
            [self subscribeForNotifications];
        }
        else {
            [self removeTapRecognizers];
            _overlayWindow = nil;
            [self shutdownScreenRecorder];
            [self unsubscribeFromNotifications];
        }
    }
}

#pragma mark - Private

- (void)recreateScreenRecorder {
    _screenRecorder = [SGASPhotoLibraryScreenRecorder new];
    __typeof(self) __weak wself = self;
    _screenRecorder.recordingCompletedBlock = ^{
        __typeof(self) sself = wself;
        if (sself) {
            dispatch_async(dispatch_get_main_queue(), ^{
                [SGASTouchVisualizer sharedVisualizer].visualizesTouches = NO;
                sself->_overlayWindow.state = SGASStatusBarOverlayWindowStateSaving;
            });
        }
    };
    _screenRecorder.saveCompletedBlock = ^(NSURL *assetURL, NSError *error) {
        if (error) {
            NSLog(@"Failed to save recorded video to photo library: %@", error);
        }
        __typeof(self) sself = wself;
        if (sself) {
            dispatch_async(dispatch_get_main_queue(), ^{
                sself->_screenRecorder = nil;
                sself->_overlayWindow.state = SGASStatusBarOverlayWindowStateIdle;
            });
        }
    };
}

- (CGRect)frameWithSize:(CGSize)size
               inCorner:(UIRectCorner)corner
  ofContainerWithBounds:(CGRect)bounds {
    CGFloat xInset = CGRectGetWidth(bounds) - size.width;
    CGFloat yInset = CGRectGetHeight(bounds) - size.height;
    UIEdgeInsets insets;
    if (_screenCorner & UIRectCornerTopLeft) {
        insets = UIEdgeInsetsMake(0, 0, yInset, xInset);
    }
    else if (_screenCorner & UIRectCornerTopRight) {
        insets = UIEdgeInsetsMake(0, xInset, yInset, 0);
    }
    else if (_screenCorner & UIRectCornerBottomLeft) {
        insets = UIEdgeInsetsMake(yInset, 0, 0, xInset);
    }
    else if (_screenCorner & UIRectCornerBottomRight) {
        insets = UIEdgeInsetsMake(yInset, xInset, 0, 0);
    }
    else {
        return CGRectZero;
    }
    return UIEdgeInsetsInsetRect(bounds,
                                 insets);
}

- (void)recreateOverlayWindow {
    _overlayWindow = [SGASStatusBarOverlayWindow new];
    _overlayWindow.hidden = NO;
    _overlayWindow.state = SGASStatusBarOverlayWindowStateIdle;
    [self updateOverlayWindowFrame];
}

- (void)toggleOverlayWindowVisibility {
    _overlayWindow.hidden = YES;
    _overlayWindow.hidden = NO;
}

- (void)updateOverlayWindowFrame {
    UIView *rootViewControllerView = [self mainApplicationWindow].rootViewController.view;
    NSCAssert(rootViewControllerView, @"rootViewController's view is nil");
    if (!rootViewControllerView) {
        return;
    }
    CGRect rootViewControllerViewBounds = rootViewControllerView.bounds;
    CGRect overlayWindowFrameInRootVC = [self frameWithSize:_overlayWindowSize
                                                   inCorner:_screenCorner
                                      ofContainerWithBounds:rootViewControllerViewBounds];
    CGRect overlayWindowFrame;
    if ([UIScreen instancesRespondToSelector:@selector(fixedCoordinateSpace)]) {
        overlayWindowFrame = [[UIScreen mainScreen].fixedCoordinateSpace convertRect:overlayWindowFrameInRootVC
                                                                fromCoordinateSpace:rootViewControllerView];
    }
    else {
        overlayWindowFrame = [[self mainApplicationWindow] convertRect:overlayWindowFrameInRootVC
                                                             fromView:rootViewControllerView];
    }
    _overlayWindow.frame = overlayWindowFrame;
}

- (UIWindow *)mainApplicationWindow {
    return [UIApplication sharedApplication].delegate.window ?: [[UIApplication sharedApplication].windows firstObject];
}

- (UITapGestureRecognizer *)createdTapRecognizerForWindow:(UIWindow *)window {
    NSCParameterAssert(window);
    if (!window) {
        return nil;
    }
    UITapGestureRecognizer *tapRecognizer = [[UITapGestureRecognizer alloc] initWithTarget:self
                                                                                    action:@selector(tapRecognizerAction:)];
    tapRecognizer.numberOfTapsRequired = kNumberOfTaps;
    tapRecognizer.numberOfTouchesRequired = kNumberOfTouches;
    tapRecognizer.delegate = self;
    [window addGestureRecognizer:tapRecognizer];
    return tapRecognizer;
}

- (void)recreateTapRecognizers {
    _mainWindowTapRecognizer = [self createdTapRecognizerForWindow:[self mainApplicationWindow]];
    UIWindow *statusBarWindow = [[UIApplication sharedApplication] valueForKey:@"_statusBarWindow"];
    if (statusBarWindow) {
        _statusbarWindowTapRecognizer = [self createdTapRecognizerForWindow:statusBarWindow];
    }
}

- (void)removeTapRecognizers {
    [_mainWindowTapRecognizer.view removeGestureRecognizer:_mainWindowTapRecognizer];
    _mainWindowTapRecognizer = nil;
    [_statusbarWindowTapRecognizer.view removeGestureRecognizer:_statusbarWindowTapRecognizer];
    _statusbarWindowTapRecognizer = nil;
}

- (void)shutdownScreenRecorder {
    _screenRecorder.recordingCompletedBlock = nil;
    _screenRecorder.saveCompletedBlock = nil;
    [_screenRecorder stopRecording];
    _screenRecorder = nil;
}

- (void)subscribeForNotifications {
    __typeof(self) __weak wself = self;
    _applicationDidChangeStatusbarOrientationObserver =
    [[NSNotificationCenter defaultCenter] addObserverForName:UIApplicationDidChangeStatusBarOrientationNotification
                                                      object:nil
                                                       queue:[NSOperationQueue mainQueue]
                                                  usingBlock:^(NSNotification *note) {
                                                      if (NSFoundationVersionNumber <= NSFoundationVersionNumber_iOS_7_1) {
                                                          // root VC's frame is changed after UIApplicationDidChangeStatusBarOrientationNotification is posted on iOS 7
                                                          dispatch_async(dispatch_get_main_queue(),
                                                                         ^{
                                                                             [wself updateOverlayWindowFrame];
                                                                         });
                                                      }
                                                      else {
                                                          [wself updateOverlayWindowFrame];
                                                      }
                                                  }];
    _windowDidBecomeKeyObserver =
    [[NSNotificationCenter defaultCenter] addObserverForName:UIWindowDidBecomeKeyNotification
                                                      object:nil
                                                       queue:[NSOperationQueue mainQueue]
                                                  usingBlock:^(NSNotification *note) {
                                                      dispatch_async(dispatch_get_main_queue(),
                                                                     ^{
                                                                         [wself toggleOverlayWindowVisibility];
                                                                     });
                                                  }];
}

- (void)unsubscribeFromNotifications {
    if (_applicationDidChangeStatusbarOrientationObserver) {
        [[NSNotificationCenter defaultCenter] removeObserver:_applicationDidChangeStatusbarOrientationObserver];
    }
    if (_windowDidBecomeKeyObserver) {
        [[NSNotificationCenter defaultCenter] removeObserver:_windowDidBecomeKeyObserver];
    }
}

#pragma mark - tap recognizer

- (void)tapRecognizerAction:(UITapGestureRecognizer *)tapRecognizer {
    if (_screenRecorder.recording) {
        [_screenRecorder stopRecording];
    }
    else {
        [self recreateScreenRecorder];
        [SGASTouchVisualizer sharedVisualizer].visualizesTouches = YES;
        [_screenRecorder startRecordingWithSettings:_screenRecorderSettings];
        _overlayWindow.state = SGASStatusBarOverlayWindowStateRecording;
    }
}

#pragma mark - UIGestureRecognizerDelegate

- (BOOL)gestureRecognizerShouldBegin:(UIGestureRecognizer *)gestureRecognizer {
    UIView *rootViewControllerView = [self mainApplicationWindow].rootViewController.view;
    NSCAssert(rootViewControllerView, @"rootViewController's view is nil");
    if (rootViewControllerView) {
        CGPoint locationInRootViewControllerView = [gestureRecognizer locationInView:rootViewControllerView];
        CGRect allowedRect = [self frameWithSize:_activationTapAreaSize
                                        inCorner:_screenCorner
                           ofContainerWithBounds:rootViewControllerView.bounds];
        return CGRectContainsPoint(allowedRect, locationInRootViewControllerView);
    }
    return NO;
}

- (BOOL)gestureRecognizer:(UIGestureRecognizer *)gestureRecognizer shouldBeRequiredToFailByGestureRecognizer:(UIGestureRecognizer *)otherGestureRecognizer {
    if ([otherGestureRecognizer isKindOfClass:[UITapGestureRecognizer class]]) {
        UITapGestureRecognizer *otherTapRecognizer = (UITapGestureRecognizer *)otherGestureRecognizer;
        return otherTapRecognizer.numberOfTapsRequired < kNumberOfTaps &&
            otherTapRecognizer.numberOfTouchesRequired == kNumberOfTouches;
    }
    return NO;
}

@end

NS_ASSUME_NONNULL_END