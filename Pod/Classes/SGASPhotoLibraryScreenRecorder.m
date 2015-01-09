//
//  SGASPhotoLibraryScreenRecorder.m
//  SGASScreenRecorder
//
//  Created by Aleksandr Gusev on 28/10/14.
//
//

#import "SGASPhotoLibraryScreenRecorder.h"
#import "SGASScreenRecorder.h"

static NSInteger const kCameraRollMaximumVideoDimension = 1660;

@interface SGASPhotoLibraryScreenRecorder () {
    SGASScreenRecorder *_screenRecorder;
    ALAssetsLibrary *_assetsLibrary;
    SGASScreenRecorderSettings *_settings;
    BOOL _saving;
}

@end

@implementation SGASPhotoLibraryScreenRecorder

@dynamic recording;

#pragma mark - Init/dealloc

- (instancetype)init {
    if (![SGASScreenRecorder isSupported]) {
        return nil;
    }
    if (self = [super init]) {
        [self setupAssetsLibraryAndScreenRecorder];
    }
    return self;
}

#pragma mark - Properties

- (BOOL)isRecording {
    return _screenRecorder.recording || _saving;
}

#pragma mark - Public

- (void)startRecordingWithSettings:(SGASScreenRecorderSettings *)settings {
    NSCParameterAssert(settings);
    if (!settings) {
        return;
    }
    NSCAssert(!self.recording, @"screen recorder is already recording");
    if (self.recording) {
        return;
    }
    _settings = settings;
    _settings.maximumVideoDimension = _settings.maximumVideoDimension ?
        @(MIN([_settings.maximumVideoDimension integerValue], kCameraRollMaximumVideoDimension)) :
        @(kCameraRollMaximumVideoDimension);
    [_screenRecorder startRecordingWithSettings:_settings
                                    toFileAtURL:[self generatedTemporaryVideoFileURL]];
}

- (void)stopRecording {
    [_screenRecorder stopRecording];
}

#pragma mark - Private

- (void)setupAssetsLibraryAndScreenRecorder {
    _assetsLibrary = [ALAssetsLibrary new];
    _screenRecorder = [SGASScreenRecorder new];
    __typeof(self) __weak wself = self;
    _screenRecorder.completionBlock = ^(NSURL *videoFileURL){
        __typeof(self) sself = wself;
        if (sself) {
            __typeof(sself.recordingCompletedBlock) recordingCompletedBlock = sself.recordingCompletedBlock;
            if (recordingCompletedBlock) {
                recordingCompletedBlock();
            }
            if ([sself->_assetsLibrary videoAtPathIsCompatibleWithSavedPhotosAlbum:videoFileURL]) {
                sself->_saving = YES;
                [sself->_assetsLibrary writeVideoAtPathToSavedPhotosAlbum:videoFileURL
                                                          completionBlock:^(NSURL *assetURL, NSError *error) {
                                                              __typeof(self) innerSself = wself;
                                                              if (innerSself) {
                                                                  [innerSself tryRemoveTemporaryVideoFile];
                                                                  innerSself->_saving = NO;
                                                                  __typeof(innerSself.saveCompletedBlock) saveCompletedBlock = innerSself.saveCompletedBlock;
                                                                  if (saveCompletedBlock) {
                                                                      saveCompletedBlock(assetURL, error);
                                                                  }
                                                              }
                                                          }];
            }
            else {
                NSLog(@"the recorded video is not compatible with saved photos album. :(");
            }
        }
    };
}

- (NSURL *)generatedTemporaryVideoFileURL {
    NSString *fileName = [NSString stringWithFormat:@"%@.%@",
                          [[NSUUID UUID] UUIDString], [SGASScreenRecorder preferredVideoFileExtension]];
    NSURL *fileURL = [NSURL fileURLWithPath:[NSTemporaryDirectory() stringByAppendingPathComponent:fileName]];
    return fileURL;
}

- (void)tryRemoveTemporaryVideoFile {
    NSError * __autoreleasing error;
    BOOL successfullyRemoved = [[NSFileManager defaultManager] removeItemAtURL:_screenRecorder.lastRecordingVideoFileURL
                                                                         error:&error];
    if (!successfullyRemoved) {
        NSLog(@"Failed to remove temporary video file: %@", error);
    }
}

@end
