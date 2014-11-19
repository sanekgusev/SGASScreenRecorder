//
//  SRScreenRecorder.h
//  ScreenRecorderHackaton
//
//  Created by Shmatlay Andrey on 21.06.13.
//  Copyright (c) 2013 Shmatlay Andrey. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "SGASScreenRecorderSettings.h"

// Based on old versions of https://github.com/coolstar/RecordMyScreen

typedef void(^SGASScreenRecorderCompletionBlock)(NSURL *videoFileURL);

@interface SGASScreenRecorder : NSObject
@property (nonatomic, readonly) SGASScreenRecorderSettings *settings;
@property (nonatomic, readonly, getter=isRecording) BOOL recording;
@property (nonatomic, readonly) NSURL *lastRecordedVideoFileURL;
@property (nonatomic, assign) BOOL shouldStopRecordingWhenMovingToBackground;
@property (nonatomic, strong) SGASScreenRecorderCompletionBlock completionBlock;

- (instancetype)initWithSettings:(SGASScreenRecorderSettings *)settings NS_DESIGNATED_INITIALIZER;

- (void)startRecordingToFileAtURL:(NSURL *)videoFileURL;
- (void)stopRecording;

+ (BOOL)isSupported;

@end
