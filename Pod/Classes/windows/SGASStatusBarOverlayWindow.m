//
//  SRDoubleTapWindow.m
//  ScreenRecorderHackaton
//
//  Created by Shmatlay Andrey on 22.06.13.
//  Edited by Aleksandr Gusev on 23/10/14
//

#import "SGASStatusBarOverlayWindow.h"

static CGFloat const kWindowWidth = 35.f;
static CGFloat const kWindowHeight = 20.f;

@interface SGASStatusBarOverlayWindow () {
    id _applicationWillChangeStatusbarOrientationObserver;
}

@end

@implementation SGASStatusBarOverlayWindow

#pragma mark - Init/dealloc

- (instancetype)init {
    if (self = [super initWithFrame:CGRectZero]) {
        self.windowLevel = UIWindowLevelStatusBar + 1.0f;
        
        self.rootViewController = [UIViewController new];
        
        [self addDoubleTapRecognizer];
        
        [self subscribeForNotifications];
        
        [self updateFrameForNewStatusBarOrientation:[[UIApplication sharedApplication] statusBarOrientation]];
        
        [self applyState];
    }
    return self;
}

- (instancetype)initWithFrame:(CGRect)frame {
    return [self init];
}

- (void)dealloc {
    [self unsubscribeFromNotifications];
}

#pragma mark - Properties

- (void)setState:(SGASStatusBarOverlayWindowState)state {
    if (_state != state) {
        _state = state;
        [self applyState];
    }
}

#pragma mark - UIWindow 

- (UIViewController *)rootViewController {
    UIWindow *mainWindow = [UIApplication sharedApplication].delegate.window;
    if (!mainWindow) {
        mainWindow = [UIApplication sharedApplication].windows.firstObject;
    }
    return mainWindow.rootViewController ?: [super rootViewController];
}

#pragma mark - Private

- (void)applyState {
    switch (_state) {
        case SGASStatusBarOverlayWindowStateIdle:
            self.backgroundColor = [UIColor colorWithRed:0x4C/(CGFloat)0xFF
                                                   green:0xD9/(CGFloat)0xFF
                                                    blue:0x64/(CGFloat)0xFF
                                                   alpha:0.1f];
            break;
        case SGASStatusBarOverlayWindowStateRecording:
            self.backgroundColor = [UIColor colorWithRed:0xFF/(CGFloat)0xFF
                                                   green:0x3B/(CGFloat)0xFF
                                                    blue:0x30/(CGFloat)0xFF
                                                   alpha:0.1f];
            break;
        default:
            NSCAssert(NO, @"invalid state");
            break;
    }
    self.layer.borderColor = [self.backgroundColor colorWithAlphaComponent:0.8f].CGColor;
    self.layer.borderWidth = 1.0f / [UIScreen mainScreen].scale;
}

- (void)updateFrameForNewStatusBarOrientation:(UIInterfaceOrientation)statusBarOrientation {
    CGRect screenBounds = CGRectZero;
    if ([UIScreen instancesRespondToSelector:@selector(fixedCoordinateSpace)]) {
        screenBounds = [[[UIScreen mainScreen] fixedCoordinateSpace] bounds];
    }
    else {
        screenBounds = [[UIScreen mainScreen] bounds];
    }
    UIEdgeInsets insets = UIEdgeInsetsZero;
    switch (statusBarOrientation) {
        case UIInterfaceOrientationPortrait:
            insets = UIEdgeInsetsMake(0,
                                      CGRectGetWidth(screenBounds) - kWindowWidth,
                                      CGRectGetHeight(screenBounds) - kWindowHeight,
                                      0);
            break;
        case UIInterfaceOrientationPortraitUpsideDown:
            insets = UIEdgeInsetsMake(CGRectGetHeight(screenBounds) - kWindowHeight,
                                      0,
                                      0,
                                      CGRectGetWidth(screenBounds) - kWindowWidth);
            break;
        case UIInterfaceOrientationLandscapeLeft:
            insets = UIEdgeInsetsMake(0,
                                      0,
                                      CGRectGetHeight(screenBounds) - kWindowWidth,
                                      CGRectGetWidth(screenBounds) - kWindowHeight);
            break;
        case UIInterfaceOrientationLandscapeRight:
            insets = UIEdgeInsetsMake(CGRectGetHeight(screenBounds) - kWindowWidth,
                                      CGRectGetWidth(screenBounds) - kWindowHeight,
                                      0,
                                      0);
            break;
        case UIInterfaceOrientationUnknown:
        default:
            NSCAssert(NO, @"unexpected interface orientation");
            break;
    }
    CGRect frame = UIEdgeInsetsInsetRect(screenBounds, insets);
    if ([UIScreen instancesRespondToSelector:@selector(fixedCoordinateSpace)]) {
        self.frame = [[[UIScreen mainScreen] coordinateSpace] convertRect:frame
    fromCoordinateSpace:[[UIScreen mainScreen] fixedCoordinateSpace]];
    }
    else {
        self.frame = frame;
    }
}

- (void)subscribeForNotifications {
    __typeof(self) __weak wself = self;
    _applicationWillChangeStatusbarOrientationObserver =
    [[NSNotificationCenter defaultCenter] addObserverForName:UIApplicationWillChangeStatusBarOrientationNotification
                                                      object:nil
                                                       queue:[NSOperationQueue mainQueue]
                                                  usingBlock:^(NSNotification *note) {
                                                      UIInterfaceOrientation newOrientation = [note.userInfo[UIApplicationStatusBarOrientationUserInfoKey] integerValue];
                                                      [wself updateFrameForNewStatusBarOrientation:newOrientation];
                                                  }];
}

- (void)unsubscribeFromNotifications {
    if (_applicationWillChangeStatusbarOrientationObserver) {
        [[NSNotificationCenter defaultCenter] removeObserver:_applicationWillChangeStatusbarOrientationObserver];
    }
}

- (void)addDoubleTapRecognizer {
    UITapGestureRecognizer *recognizer = [[UITapGestureRecognizer alloc] initWithTarget:self
                                                                                 action:@selector(handleDoubleTap:)];
    recognizer.numberOfTapsRequired = 2;
    [self addGestureRecognizer:recognizer];
}

- (void)handleDoubleTap:(id)sender {
    [_tapDelegate statusBarOverlayWindowDidReceiveDoubleTap:self];
}

@end
