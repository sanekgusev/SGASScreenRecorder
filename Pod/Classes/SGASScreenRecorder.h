//
//  SRScreenRecorder.h
//  ScreenRecorderHackaton
//
//  Created by Shmatlay Andrey on 21.06.13.
//  Copyright (c) 2013 Shmatlay Andrey. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "SGASScreenRecorderSettings.h"

// Based on of https://github.com/coolstar/RecordMyScreen

typedef void(^SGASScreenRecorderCompletionBlock)(NSURL *videoFileURL);

@interface SGASScreenRecorder : NSObject
@property (nonatomic, readonly) SGASScreenRecorderSettings *lastRecordingSettings;
@property (nonatomic, readonly) NSURL *lastRecordingVideoFileURL;

@property (nonatomic, readonly, getter=isRecording) BOOL recording;

@property (nonatomic, strong) SGASScreenRecorderCompletionBlock completionBlock;

- (void)startRecordingWithSettings:(SGASScreenRecorderSettings *)settings
                       toFileAtURL:(NSURL *)videoFileURL;
- (void)stopRecording;

+ (BOOL)isSupported;

@end
