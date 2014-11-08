//
//  SGASScreenRecorderUIManager.m
//  Pods
//
//  Created by Aleksandr Gusev on 23/10/14.
//
//

#import "SGASScreenRecorderUIManager.h"
#import "SGASStatusBarOverlayWindow.h"
#import "SGASPhotoLibraryScreenRecorder.h"
#import "SGASTouchVisualizer.h"

typedef NS_ENUM(NSInteger, OverlayWindowState) {
    OverlayWindowStateIdle,
    OverlayWindowStateRecording,
};

@interface SGASScreenRecorderUIManager ()<UIAlertViewDelegate,
SGASStatusBarOverlayWindowDelegate> {
    SGASPhotoLibraryScreenRecorder * _screenRecorder;
    SGASStatusBarOverlayWindow *_overlayWindow;
}

@end

@implementation SGASScreenRecorderUIManager

#pragma mark - Singleton

+ (instancetype)sharedManager {
    static SGASScreenRecorderUIManager *SharedManager = nil;
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        SharedManager = [SGASScreenRecorderUIManager new];
    });
    return SharedManager;
}

#pragma mark - Properties

- (void)setEnabled:(BOOL)enabled {
    if (_enabled != !!enabled) {
        _enabled = !!enabled;
        if (_enabled) {
            _overlayWindow = [SGASStatusBarOverlayWindow new];
            _overlayWindow.tapDelegate = self;
            _overlayWindow.hidden = NO;
            [self setOverlayWindowState:OverlayWindowStateIdle];
        }
        else {
            _screenRecorder.completionBlock = nil;
            _screenRecorder.recording = NO;
            _screenRecorder = nil;
            _overlayWindow = nil;
        }
    }
}

#pragma mark - Private

- (void)setOverlayWindowState:(OverlayWindowState)state {
    _overlayWindow.backgroundColor = [state == OverlayWindowStateIdle ?
                                      [UIColor greenColor] : [UIColor redColor] colorWithAlphaComponent:0.4f];
}

- (void)recreateScreenRecorder {
    _screenRecorder = [SGASPhotoLibraryScreenRecorder new];
    __typeof(self) __weak wself = self;
    _screenRecorder.completionBlock = ^(NSURL *assetURL, NSError *error) {
        __typeof(self) sself = wself;
        if (sself) {
            dispatch_async(dispatch_get_main_queue(), ^{
                sself->_screenRecorder = nil;
                [SGASTouchVisualizer sharedVisualizer].visualizesTouches = NO;
                [sself setOverlayWindowState:OverlayWindowStateIdle];
            });
        }
    };
}

#pragma mark - SGASStatusBarOverlayWindowDelegate
- (void)statusBarOverlayWindowDidReceiveDoubleTap:(SGASStatusBarOverlayWindow *)window {
    if (_screenRecorder.recording) { //TODO: recording or saving?
        _screenRecorder.recording = NO;
    }
    else {
        UIAlertView *alert = [[UIAlertView alloc] initWithTitle:@"Begin recording?"
                                                        message:nil
                                                       delegate:self
                                              cancelButtonTitle:@"Cancel"
                                              otherButtonTitles:@"OK", nil];
        [alert show];
    }
}

#pragma mark - UIAlertViewDelegate
- (void)alertView:(UIAlertView *)alertView didDismissWithButtonIndex:(NSInteger)buttonIndex {
    if (buttonIndex != [alertView cancelButtonIndex]) {
        [self recreateScreenRecorder];
        [SGASTouchVisualizer sharedVisualizer].visualizesTouches = YES;
        _screenRecorder.recording = YES;
        [self setOverlayWindowState:OverlayWindowStateRecording];
    }
}

@end

