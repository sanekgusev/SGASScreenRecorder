//
//  SGASScreenRecorderSettings.m
//  SGASScreenRecorder
//
//  Created by Shmatlay Andrey on 22.06.13.
//  Edited by Aleksandr Gusev on 23/10/14
//


#import "SGASScreenRecorderSettings.h"
#import <AVFoundation/AVFoundation.h>

static NSUInteger const kCameraRollMaximumVideoDimension = 1660;

@interface SGASScreenRecorderSettings () {
    NSMutableDictionary *_videoCompressionProperties;
}

@end

@implementation SGASScreenRecorderSettings

@synthesize videoCompressionProperties = _videoCompressionProperties;

- (instancetype)init {
    if (self = [super init]) {
        _framesPerSecond = 60;
        _maximumVideoDimension = kCameraRollMaximumVideoDimension;
        _videoCompressionProperties = [@{
                                 AVVideoAverageBitRateKey      : @(2048 * 1024),
                                 AVVideoProfileLevelKey        : AVVideoProfileLevelH264HighAutoLevel,
                                 AVVideoAllowFrameReorderingKey : @NO,
                                 AVVideoH264EntropyModeKey: AVVideoH264EntropyModeCABAC,
                                 AVVideoExpectedSourceFrameRateKey: @(_framesPerSecond),
                                 } mutableCopy];
    }
    return self;
}

- (void)setFramesPerSecond:(NSUInteger)framesPerSecond {
    _framesPerSecond = framesPerSecond;
    _videoCompressionProperties[AVVideoExpectedSourceFrameRateKey] = @(_framesPerSecond);
}

- (void)setVideoCompressionProperties:(NSDictionary *)videoCompressionProperties {
    _videoCompressionProperties = [videoCompressionProperties mutableCopy];
    _videoCompressionProperties[AVVideoExpectedSourceFrameRateKey] = @(_framesPerSecond);
}

@end
