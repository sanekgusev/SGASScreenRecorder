//
//  SGASScreenRecorderUIManager.m
//  Pods
//
//  Created by Aleksandr Gusev on 23/10/14.
//
//

#import "SGASScreenRecorderUIManager.h"
#import "SGASStatusBarOverlayWindow.h"
#import "SGASPhotoLibraryScreenRecorder.h"
#import "SGASTouchVisualizer.h"

static CGSize const kDefaultOverlayWindowSize = (CGSize){40.0f, 20.0f};
static CGSize const kDefaultActivationTapAreaSize = (CGSize){44.0f, 44.0f};

@interface SGASScreenRecorderUIManager ()<UIGestureRecognizerDelegate> {
    
    UIRectCorner _screenCorner;
    CGSize _overlayWindowSize;
    CGSize _activationTapAreaSize;
    
    SGASPhotoLibraryScreenRecorder * _screenRecorder;
    SGASStatusBarOverlayWindow *_overlayWindow;
    UITapGestureRecognizer *_mainWindowTapRecognizer;
    UITapGestureRecognizer *_overlayWindowTapRecognizer;
    
    id _applicationDidChangeStatusbarOrientationObserver;
}

@end

@implementation SGASScreenRecorderUIManager

#pragma mark - Init/dealloc

- (instancetype)initWithScreenCorner:(UIRectCorner)screenCorner
                   overlayWindowSize:(CGSize)overlayWindowSize
               activationTapAreaSize:(CGSize)activationTapAreaSize {
    if (self = [super init]) {
        _screenCorner = screenCorner;
        _overlayWindowSize = overlayWindowSize;
        _activationTapAreaSize = activationTapAreaSize;
    }
    return self;
}

- (instancetype)initWithScreenCorner:(UIRectCorner)screenCorner {
    return [self initWithScreenCorner:screenCorner
            overlayWindowSize:kDefaultOverlayWindowSize
                activationTapAreaSize:kDefaultActivationTapAreaSize];
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
    _screenRecorder = [[SGASPhotoLibraryScreenRecorder alloc] initWithSettings:[SGASScreenRecorderSettings new]];
    __typeof(self) __weak wself = self;
    _screenRecorder.completionBlock = ^(NSURL *assetURL, NSError *error) {
        __typeof(self) sself = wself;
        if (sself) {
            dispatch_async(dispatch_get_main_queue(), ^{
                sself->_screenRecorder = nil;
                [SGASTouchVisualizer sharedVisualizer].visualizesTouches = NO;
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
    tapRecognizer.numberOfTapsRequired = 3;
    tapRecognizer.delegate = self;
    [window addGestureRecognizer:tapRecognizer];
    return tapRecognizer;
}

- (void)recreateTapRecognizers {
    _mainWindowTapRecognizer = [self createdTapRecognizerForWindow:[self mainApplicationWindow]];
    _overlayWindowTapRecognizer = [self createdTapRecognizerForWindow:_overlayWindow];
}

- (void)removeTapRecognizers {
    [_mainWindowTapRecognizer.view removeGestureRecognizer:_mainWindowTapRecognizer];
    _mainWindowTapRecognizer = nil;
    [_overlayWindowTapRecognizer.view removeGestureRecognizer:_overlayWindowTapRecognizer];
    _overlayWindowTapRecognizer = nil;
}

- (void)shutdownScreenRecorder {
    _screenRecorder.completionBlock = nil;
    _screenRecorder.recording = NO;
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
                                                          dispatch_async(dispatch_get_main_queue(),
                                                                         ^{
                                                                             [wself updateOverlayWindowFrame];
                                                                         });
                                                      }
                                                      else {
                                                          [wself updateOverlayWindowFrame];
                                                      }
                                                  }];
}

- (void)unsubscribeFromNotifications {
    if (_applicationDidChangeStatusbarOrientationObserver) {
        [[NSNotificationCenter defaultCenter] removeObserver:_applicationDidChangeStatusbarOrientationObserver];
    }
}

#pragma mark - tap recognizer

- (void)tapRecognizerAction:(UITapGestureRecognizer *)tapRecognizer {
    if (_screenRecorder.recording) { //TODO: replace with recording OR saving check?
        _screenRecorder.recording = NO;
    }
    else {
        [self recreateScreenRecorder];
        [SGASTouchVisualizer sharedVisualizer].visualizesTouches = YES;
        _screenRecorder.recording = YES;
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

- (BOOL)gestureRecognizer:(UIGestureRecognizer *)gestureRecognizer
    shouldBeRequiredToFailByGestureRecognizer:(UIGestureRecognizer *)otherGestureRecognizer {
    if ([otherGestureRecognizer isKindOfClass:[UITapGestureRecognizer class]]) {
        UITapGestureRecognizer *otherTapRecognizer = (UITapGestureRecognizer *)otherGestureRecognizer;
        return otherTapRecognizer.numberOfTapsRequired < 3;
    }
    return NO;
}

- (BOOL)gestureRecognizer:(UIGestureRecognizer *)gestureRecognizer
shouldRecognizeSimultaneouslyWithGestureRecognizer:(UIGestureRecognizer *)otherGestureRecognizer {
    return YES;
}

@end

