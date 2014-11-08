//
//  SRDoubleTapWindow.m
//  ScreenRecorderHackaton
//
//  Created by Shmatlay Andrey on 22.06.13.
//  Edited by Aleksandr Gusev on 23/10/14
//

#import "SGASStatusBarOverlayWindow.h"

static CGFloat const kWindowWidth = 40.f;

@interface SGASStatusBarOverlayWindow () {
    id _applicationWillChangeStatusBarFrameObserver;
}

@end

@implementation SGASStatusBarOverlayWindow

#pragma mark - Init/dealloc

- (instancetype)init {
    if (self = [super initWithFrame:CGRectZero]) {
        self.backgroundColor = [UIColor clearColor];
        self.windowLevel = UIWindowLevelStatusBar + 1.0f;
        
        [self addDoubleTapRecognizer];
        
        [self subscribeForNotifications];
        
        [self updateFrameForNewStatusBarFrame:[UIApplication sharedApplication].statusBarFrame];
    }
    return self;
}

- (instancetype)initWithFrame:(CGRect)frame {
    return [self init];
}

- (void)dealloc {
    [self unsubscribeFromNotifications];
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

- (void)updateFrameForNewStatusBarFrame:(CGRect)statusBarFrame {
    UIEdgeInsets insets = UIEdgeInsetsMake(0,
                                           CGRectGetWidth(statusBarFrame) - kWindowWidth,
                                           0,
                                           0);
    if (NSFoundationVersionNumber <= NSFoundationVersionNumber_iOS_7_1) {
        if (CGRectGetMinY(statusBarFrame) > 0) {
            insets = UIEdgeInsetsMake(0,
                                      0,
                                      0,
                                      CGRectGetWidth(statusBarFrame) - kWindowWidth);
        }
        else if (CGRectGetMinX(statusBarFrame) > 0) {
            insets = UIEdgeInsetsMake(CGRectGetHeight(statusBarFrame) - kWindowWidth,
                                      0,
                                      0,
                                      0);
        }
        else if (CGRectGetHeight(statusBarFrame) > CGRectGetWidth(statusBarFrame)) {
            insets = UIEdgeInsetsMake(0,
                                      0,
                                      CGRectGetHeight(statusBarFrame) - kWindowWidth,
                                      0);
        }
    }
    
    self.frame = UIEdgeInsetsInsetRect(statusBarFrame, insets);
}

- (void)subscribeForNotifications {
    __typeof(self) __weak wself = self;
    _applicationWillChangeStatusBarFrameObserver =
    [[NSNotificationCenter defaultCenter] addObserverForName:UIApplicationWillChangeStatusBarFrameNotification
                                                      object:nil
                                                       queue:[NSOperationQueue mainQueue]
                                                  usingBlock:^(NSNotification *note) {
                                                      CGRect newStatusBarFrame = [note.userInfo[UIApplicationStatusBarFrameUserInfoKey] CGRectValue];
                                                      [wself updateFrameForNewStatusBarFrame:newStatusBarFrame];
                                                  }];
}

- (void)unsubscribeFromNotifications {
    if (_applicationWillChangeStatusBarFrameObserver) {
        [[NSNotificationCenter defaultCenter] removeObserver:_applicationWillChangeStatusBarFrameObserver];
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
