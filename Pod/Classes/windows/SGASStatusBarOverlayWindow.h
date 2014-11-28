//
//  SRDoubleTapWindow.h
//  ScreenRecorderHackaton
//
//  Created by Shmatlay Andrey on 22.06.13.
//  Copyright (c) 2013 Shmatlay Andrey. All rights reserved.
//

#import <UIKit/UIKit.h>

typedef NS_ENUM(NSInteger, SGASStatusBarOverlayWindowState) {
    SGASStatusBarOverlayWindowStateIdle,
    SGASStatusBarOverlayWindowStateRecording,
};

@interface SGASStatusBarOverlayWindow : UIWindow
@property (nonatomic, assign) SGASStatusBarOverlayWindowState state;

@end
