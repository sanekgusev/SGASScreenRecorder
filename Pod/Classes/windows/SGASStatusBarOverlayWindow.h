//
//  SGASStatusBarOverlayWindow.h
//  SGASScreenRecorder
//
//  Created by Shmatlay Andrey on 22.06.13.
//  
//

#import <UIKit/UIKit.h>

NS_ASSUME_NONNULL_BEGIN

typedef NS_ENUM(NSInteger, SGASStatusBarOverlayWindowState) {
    SGASStatusBarOverlayWindowStateIdle,
    SGASStatusBarOverlayWindowStateRecording,
    SGASStatusBarOverlayWindowStateSaving,
};

@interface SGASStatusBarOverlayWindow : UIWindow
@property (nonatomic, assign) SGASStatusBarOverlayWindowState state;

- (instancetype)initWithCoder:(NSCoder *)aDecoder NS_UNAVAILABLE;

@end

NS_ASSUME_NONNULL_END