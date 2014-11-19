//
//  SRDoubleTapWindow.h
//  ScreenRecorderHackaton
//
//  Created by Shmatlay Andrey on 22.06.13.
//  Copyright (c) 2013 Shmatlay Andrey. All rights reserved.
//

#import <UIKit/UIKit.h>

@protocol SGASStatusBarOverlayWindowDelegate;

typedef NS_ENUM(NSInteger, SGASStatusBarOverlayWindowState) {
    SGASStatusBarOverlayWindowStateIdle,
    SGASStatusBarOverlayWindowStateRecording,
};

@interface SGASStatusBarOverlayWindow : UIWindow
@property (nonatomic, weak) id<SGASStatusBarOverlayWindowDelegate> tapDelegate;
@property (nonatomic, assign) SGASStatusBarOverlayWindowState state;

- (instancetype)init NS_DESIGNATED_INITIALIZER;

@end

@protocol SGASStatusBarOverlayWindowDelegate <NSObject>
- (void)statusBarOverlayWindowDidReceiveDoubleTap:(SGASStatusBarOverlayWindow *)window;
@end
