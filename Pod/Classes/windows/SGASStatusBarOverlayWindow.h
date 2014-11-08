//
//  SRDoubleTapWindow.h
//  ScreenRecorderHackaton
//
//  Created by Shmatlay Andrey on 22.06.13.
//  Copyright (c) 2013 Shmatlay Andrey. All rights reserved.
//

#import <UIKit/UIKit.h>

@protocol SGASStatusBarOverlayWindowDelegate;

@interface SGASStatusBarOverlayWindow : UIWindow
@property (nonatomic, weak) id<SGASStatusBarOverlayWindowDelegate> tapDelegate;

- (instancetype)init NS_DESIGNATED_INITIALIZER;

@end

@protocol SGASStatusBarOverlayWindowDelegate <NSObject>
- (void)statusBarOverlayWindowDidReceiveDoubleTap:(SGASStatusBarOverlayWindow *)window;
@end
