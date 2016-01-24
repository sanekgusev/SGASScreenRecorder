//
//  SGASScreenRecorder.h
//  SGASScreenRecorder
//
//  Created by Shmatlay Andrey on 21.06.13.
//  
//

#import <Foundation/Foundation.h>
#import "SGASScreenRecorderSettings.h"

NS_ASSUME_NONNULL_BEGIN

typedef void(^SGASScreenRecorderCompletionBlock)(NSURL *videoFileURL);

@interface SGASScreenRecorder : NSObject
@property (nonatomic, readonly) SGASScreenRecorderSettings *lastRecordingSettings;
@property (nonatomic, readonly) NSURL *lastRecordingVideoFileURL;

@property (nonatomic, readonly, getter=isRecording) BOOL recording;

@property (atomic, strong, nullable) SGASScreenRecorderCompletionBlock completionBlock;

- (void)startRecordingWithSettings:(SGASScreenRecorderSettings *)settings
                       toFileAtURL:(NSURL *)videoFileURL;
- (void)stopRecording;

+ (BOOL)isSupported;
+ (nullable NSString *)preferredVideoFileExtension;

@end

NS_ASSUME_NONNULL_END