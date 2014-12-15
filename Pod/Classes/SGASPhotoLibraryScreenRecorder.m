//
//  SGASPhotoLibraryScreenRecorder.m
//  Pods
//
//  Created by Aleksandr Gusev on 28/10/14.
//
//

#import "SGASPhotoLibraryScreenRecorder.h"
#import "SGASScreenRecorder.h"

@interface SGASPhotoLibraryScreenRecorder () {
    SGASScreenRecorder *_screenRecorder;
    ALAssetsLibrary *_assetsLibrary;
    BOOL _saving;
}

@end

@implementation SGASPhotoLibraryScreenRecorder

@dynamic recording;

#pragma mark - Init/dealloc

- (instancetype)initWithSettings:(SGASScreenRecorderSettings *)settings {
    NSCParameterAssert(settings);
    if (!settings) {
        return nil;
    }
    if (![SGASScreenRecorder isSupported]) {
        return nil;
    }
    if (self = [super init]) {
        _settings = settings;
        [self setupAssetsLibraryAndScreenRecorder];
    }
    return self;
}

- (instancetype)init {
    [self doesNotRecognizeSelector:_cmd];
    return [self initWithSettings:nil];
}

#pragma mark - Properties

- (void)setRecording:(BOOL)recording {
    if (recording) {
        NSCAssert(!self.recording, @"screen recorder is already recording");
        [_screenRecorder startRecordingWithSettings:_settings
                                        toFileAtURL:[self generatedTemporaryVideoFileURL]];
    }
    else {
        [_screenRecorder stopRecording];
    }
}

- (BOOL)isRecording {
    return _screenRecorder.recording || _saving;
}

#pragma mark - Private

- (void)setupAssetsLibraryAndScreenRecorder {
    _assetsLibrary = [ALAssetsLibrary new];
    _screenRecorder = [SGASScreenRecorder new];
    __typeof(self) __weak wself = self;
    _screenRecorder.completionBlock = ^(NSURL *videoFileURL){
        __typeof(self) sself = wself;
        if (sself) {
            if (sself.recordingCompletedBlock) {
                sself.recordingCompletedBlock();
            }
            if ([sself->_assetsLibrary videoAtPathIsCompatibleWithSavedPhotosAlbum:videoFileURL]) {
                sself->_saving = YES;
                [sself->_assetsLibrary writeVideoAtPathToSavedPhotosAlbum:videoFileURL
                                                          completionBlock:^(NSURL *assetURL, NSError *error) {
                                                              __typeof(self) innerSself = wself;
                                                              if (innerSself) {
                                                                  [innerSself tryRemoveTemporaryVideoFile];
                                                                  innerSself->_saving = NO;
                                                                  if (innerSself.saveCompletedBlock) {
                                                                      innerSself.saveCompletedBlock(assetURL, error);
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
    NSString *fileName = [NSString stringWithFormat:@"%@.mp4",
                          [[NSUUID UUID] UUIDString]];
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
