//
//  SGASScreenRecorder.h
//  SGASScreenRecorder
//
//  Created by Shmatlay Andrey on 21.06.13.
//  
//

#import <Foundation/Foundation.h>
#import "SGASScreenRecorderSettings.h"

typedef void(^SGASScreenRecorderCompletionBlock)(NSURL *videoFileURL);

@interface SGASScreenRecorder : NSObject
@property (nonatomic, readonly) SGASScreenRecorderSettings *lastRecordingSettings;
@property (nonatomic, readonly) NSURL *lastRecordingVideoFileURL;

@property (nonatomic, readonly, getter=isRecording) BOOL recording;

@property (atomic, strong) SGASScreenRecorderCompletionBlock completionBlock;

- (void)startRecordingWithSettings:(SGASScreenRecorderSettings *)settings
                       toFileAtURL:(NSURL *)videoFileURL;
- (void)stopRecording;

+ (BOOL)isSupported;
+ (NSString *)preferredVideoFileExtension;

@end
