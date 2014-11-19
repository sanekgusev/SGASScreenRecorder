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

- (void)recreateScreenRecorder {
    _screenRecorder = [SGASPhotoLibraryScreenRecorder new];
    __typeof(self) __weak wself = self;
    _screenRecorder.completionBlock = ^(NSURL *assetURL, NSError *error) {
        __typeof(self) sself = wself;
        if (sself) {
            dispatch_async(dispatch_get_main_queue(), ^{
                sself->_screenRecorder = nil;
                [SGASTouchVisualizer sharedVisualizer].visualizesTouches = NO;
                sself->_overlayWindow.state = SGASStatusBarOverlayWindowStateIdle;
            });
        }
    };
}

#pragma mark - SGASStatusBarOverlayWindowDelegate
- (void)statusBarOverlayWindowDidReceiveDoubleTap:(SGASStatusBarOverlayWindow *)window {
    if (_screenRecorder.recording) { //TODO: replace with recording OR saving check?
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
        _overlayWindow.state = SGASStatusBarOverlayWindowStateRecording;
    }
}

@end

