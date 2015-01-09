//
//  SGASStatusBarOverlayWindow.h
//  SGASScreenRecorder
//
//  Created by Shmatlay Andrey on 22.06.13.
//  
//

#import <UIKit/UIKit.h>

typedef NS_ENUM(NSInteger, SGASStatusBarOverlayWindowState) {
    SGASStatusBarOverlayWindowStateIdle,
    SGASStatusBarOverlayWindowStateRecording,
    SGASStatusBarOverlayWindowStateSaving,
};

@interface SGASStatusBarOverlayWindow : UIWindow
@property (nonatomic, assign) SGASStatusBarOverlayWindowState state;

@end
