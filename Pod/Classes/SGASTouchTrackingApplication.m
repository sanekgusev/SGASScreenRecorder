//
//  UIWindow+SRRecorder.m
//  ScreenRecorderHackaton
//
//  Created by Shmatlay Andrey on 21.06.13.
//  Edited by Aleksandr Gusev on 23/10/14
//

#import "SGASTouchTrackingApplication.h"
#import <objc/message.h>

NSString * const SGASTouchTrackingApplicationTouchEventNotification = @"SGASApplicationTouchEventNotification";
NSString * const SGASTouchTrackingApplicationTouchEventKey = @"SGASApplicationTouchEventKey";

@implementation SGASTouchTrackingApplication

#pragma mark - NSObject

- (Class)class {
    return class_getSuperclass(object_getClass(self));
}

#pragma mark - UIApplication

- (void)sendEvent:(UIEvent *)event {
    BOOL touchEvent = event.type == UIEventTypeTouches;
    if (touchEvent) {
        [[NSNotificationCenter defaultCenter] postNotificationName:SGASTouchTrackingApplicationTouchEventNotification
                                                            object:self
                                                          userInfo:@{SGASTouchTrackingApplicationTouchEventKey: event}];
    }
    struct objc_super sup;
    sup.receiver = self;
    sup.super_class = class_getSuperclass(object_getClass(self));
    ((void(*)(struct objc_super *, SEL, UIEvent *))objc_msgSendSuper)(&sup, _cmd, event);
}

@end
