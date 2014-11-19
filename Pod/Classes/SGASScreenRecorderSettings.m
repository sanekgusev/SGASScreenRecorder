//
//  SRRecorderSettings.m
//  ScreenRecorderHackaton
//
//  Created by Shmatlay Andrey on 22.06.13.
//  Edited by Aleksandr Gusev on 23/10/14
//


#import "SGASScreenRecorderSettings.h"
#import <AVFoundation/AVFoundation.h>

static NSUInteger const kCameraRollMaximumVideoDimension = 1665;

@interface SGASScreenRecorderSettings () {
    NSMutableDictionary *_compressionSettings;
}

@end

@implementation SGASScreenRecorderSettings

@synthesize compressionSettings = _compressionSettings;

- (instancetype)init {
    if (self = [super init]) {
        _framesPerSecond = 60;
        _maximumOutputVideoDimension = kCameraRollMaximumVideoDimension;
        _compressionSettings = [@{
                                 AVVideoAverageBitRateKey      : @(1024 * 1024),
                                 AVVideoProfileLevelKey        : AVVideoProfileLevelH264HighAutoLevel,
                                 AVVideoAllowFrameReorderingKey : @YES,
                                 AVVideoH264EntropyModeKey: AVVideoH264EntropyModeCABAC,
                                 AVVideoExpectedSourceFrameRateKey: @(_framesPerSecond),
                                 } mutableCopy];
    }
    return self;
}

- (void)setFramesPerSecond:(NSInteger)framesPerSecond {
    _framesPerSecond = framesPerSecond;
    _compressionSettings[AVVideoExpectedSourceFrameRateKey] = @(_framesPerSecond);
}

@end
