//
//  UIWindow+SRRecorder.m
//  ScreenRecorderHackaton
//
//  Created by Shmatlay Andrey on 21.06.13.
//  Edited by Aleksandr Gusev on 23/10/14
//

#import "SGASApplication.h"

NSString * const SGASApplicationTouchEventNotification = @"SGASApplicationTouchEventNotification";
NSString * const SGASApplicationTouchEventKey = @"SGASApplicationTouchEventKey";

@implementation SGASApplication

#pragma mark - NSObject

- (Class)class {
    return [[super class] superclass];
}

#pragma mark - UIApplication

- (void)sendEvent:(UIEvent *)event {
    BOOL touchEvent = event.type == UIEventTypeTouches;
    if (touchEvent) {
        [[NSNotificationCenter defaultCenter] postNotificationName:SGASApplicationTouchEventNotification
                                                            object:self
                                                          userInfo:@{SGASApplicationTouchEventKey: event}];
    }
    [super sendEvent:event];
}

@end
