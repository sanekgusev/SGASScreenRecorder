//
//  SGASPhotoLibraryScreenRecorder.h
//  Pods
//
//  Created by Aleksandr Gusev on 28/10/14.
//
//

#import <Foundation/Foundation.h>
#import <AssetsLibrary/AssetsLibrary.h>
#import "SGASScreenRecorderSettings.h"

typedef void(^SGASPhotoLibraryScreenRecorderCompletionBlock)(NSURL *videoAssetURL, NSError *error);

@interface SGASPhotoLibraryScreenRecorder : NSObject

@property (nonatomic, readonly) SGASScreenRecorderSettings *settings;
@property (nonatomic, assign, getter=isRecording) BOOL recording;
@property (nonatomic, strong) SGASPhotoLibraryScreenRecorderCompletionBlock completionBlock;

- (instancetype)initWithSettings:(SGASScreenRecorderSettings *)settings NS_DESIGNATED_INITIALIZER;

@end
