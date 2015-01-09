//
//  SGASPhotoLibraryScreenRecorder.h
//  SGASScreenRecorder
//
//  Created by Aleksandr Gusev on 28/10/14.
//
//

#import <Foundation/Foundation.h>
#import <AssetsLibrary/AssetsLibrary.h>
#import "SGASScreenRecorderSettings.h"

typedef void(^SGASPhotoLibraryScreenRecorderRecordingCompletedBlock)(void);
typedef void(^SGASPhotoLibraryScreenRecorderSavingCompletedBlock)(NSURL *videoAssetURL, NSError *error);

@interface SGASPhotoLibraryScreenRecorder : NSObject

@property (nonatomic, readonly) SGASScreenRecorderSettings *settings;
@property (nonatomic, readonly, getter=isRecording) BOOL recording;
@property (nonatomic, strong) SGASPhotoLibraryScreenRecorderRecordingCompletedBlock recordingCompletedBlock;
@property (nonatomic, strong) SGASPhotoLibraryScreenRecorderSavingCompletedBlock saveCompletedBlock;

- (void)startRecordingWithSettings:(SGASScreenRecorderSettings *)settings;
- (void)stopRecording;

@end
