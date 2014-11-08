//
//  SGASScreenRecorderTapVisualizer.m
//  Pods
//
//  Created by Aleksandr Gusev on 23/10/14.
//
//

#import "SGASTouchVisualizer.h"
#import "NSObject+SGVObjcMixin.h"
#import "SGASApplication.h"
#import "SGASTouchVisualizationWindow.h"

@interface SGASTouchVisualizer () {
    id _applicationTouchEventObserver;
    NSHashTable *_reusableWindows;
    NSMapTable *_windowsForTouches;
}

@end

static NSTimeInterval const kTouchFadeInFadeOutDuration = 0.1;

@implementation SGASTouchVisualizer

#pragma mark - Init/dealloc

- (instancetype)init {
    if (self = [super init]) {
        _reusableWindows = [NSHashTable hashTableWithOptions:NSHashTableStrongMemory | NSHashTableObjectPointerPersonality];
        _windowsForTouches = [NSMapTable weakToStrongObjectsMapTable];
    }
    return self;
}

- (void)dealloc {
    self.visualizesTouches = NO;
}

#pragma mark - Singleton

+ (instancetype)sharedVisualizer {
    static SGASTouchVisualizer *TapVisualizer = nil;
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        TapVisualizer = [SGASTouchVisualizer new];
    });
    return TapVisualizer;
}

#pragma mark - Properties

- (void)setVisualizesTouches:(BOOL)visualizesTaps {
    if (_visualizesTouches != !!visualizesTaps) {
        _visualizesTouches = visualizesTaps;
        NSError * __autoreleasing error;
        if (_visualizesTouches) {
            BOOL __unused mixinResult = [[UIApplication sharedApplication] sgv_mixinClass:[SGASApplication class]
                                                                                    error:&error];
            NSCAssert(mixinResult, @"mixing in should be successful");
            [self subscribeToNotifications];
        }
        else {
            BOOL __unused unmixinResult = [[UIApplication sharedApplication] sgv_unmixinClass:[SGASApplication class]
                                                                                        error:&error];
            NSCAssert(unmixinResult, @"un-mixing in should be successful");
            [self unsubscribeFromNotifications];
        }
    }
}

#pragma mark - Private

- (void)subscribeToNotifications {
    __typeof(self) __weak wself = self;
    _applicationTouchEventObserver =
        [[NSNotificationCenter defaultCenter] addObserverForName:SGASApplicationTouchEventNotification
                                                          object:nil
                                                           queue:[NSOperationQueue mainQueue]
                                                      usingBlock:^(NSNotification *note) {
                                                          [wself handleEvent:note.userInfo[SGASApplicationTouchEventKey]];
                                                      }];
}

- (void)unsubscribeFromNotifications {
    if (_applicationTouchEventObserver) {
        [[NSNotificationCenter defaultCenter] removeObserver:_applicationTouchEventObserver];
        _applicationTouchEventObserver = nil;
    }
}

- (void)handleEvent:(UIEvent *)event {
    
    UIWindow *mainWindow = [[UIApplication sharedApplication] windows].firstObject;
    for (UITouch *touch in [event allTouches]) {
        
        SGASTouchVisualizationWindow *tapWindow = [self tapWindowForTouch:touch];
        
        switch (touch.phase) {
            case UITouchPhaseBegan:{
                tapWindow.hidden = NO;
                tapWindow.alpha = 0.0f;
                [UIView animateWithDuration:kTouchFadeInFadeOutDuration
                                      delay:0.0
                                    options:UIViewAnimationOptionAllowUserInteraction
                                 animations:^{
                                     tapWindow.alpha = 1.0f;
                                 } completion:nil];
            }
            case UITouchPhaseMoved:
            case UITouchPhaseStationary:
                tapWindow.center = [touch locationInView:mainWindow];
                break;
            case UITouchPhaseCancelled:
            case UITouchPhaseEnded:{
                [UIView animateWithDuration:kTouchFadeInFadeOutDuration
                                      delay:0.0
                                    options:UIViewAnimationOptionAllowUserInteraction
                                 animations:^{
                                     tapWindow.alpha = 0.0f;
                                 } completion:^(BOOL finished) {
                                     tapWindow.alpha = 1.0f;
                                     tapWindow.hidden = YES;
                                     [self removeTapWindowForTouch:touch];
                                 }];
                break;
            }
            default:
                NSCAssert(NO, @"unknown touch phase");
                break;
        }
    }
}

- (SGASTouchVisualizationWindow *)tapWindowForTouch:(UITouch *)touch {
    SGASTouchVisualizationWindow *tapWindow = [_windowsForTouches objectForKey:touch];
    if (!tapWindow) {
        tapWindow = [_reusableWindows anyObject];
        if (tapWindow) {
            [_reusableWindows removeObject:tapWindow];
        }
        else {
            tapWindow = [SGASTouchVisualizationWindow new];
        }
        [_windowsForTouches setObject:tapWindow forKey:touch];
    }
    return tapWindow;
}

- (void)removeTapWindowForTouch:(UITouch *)touch {
    SGASTouchVisualizationWindow *tapWindow = [_windowsForTouches objectForKey:touch];
    [_windowsForTouches removeObjectForKey:touch];
    [_reusableWindows addObject:tapWindow];
}

@end

