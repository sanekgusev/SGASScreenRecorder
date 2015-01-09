//
//  SGASScreenRecorderSettings.m
//  SGASScreenRecorder
//
//  Created by Shmatlay Andrey on 22.06.13.
//  Edited by Aleksandr Gusev on 23/10/14
//


#import "SGASScreenRecorderSettings.h"
#import <AVFoundation/AVFoundation.h>

static NSInteger const kDefaultVideoBitRate = 2048 * 1024;

@interface SGASScreenRecorderSettings () {
    NSMutableDictionary *_videoCompressionProperties;
}

@end

@implementation SGASScreenRecorderSettings

@synthesize videoCompressionProperties = _videoCompressionProperties;

#pragma mark - Init/dealloc

- (instancetype)init {
    if (self = [super init]) {
        _framesPerSecond = 60;
        _videoCompressionProperties = [[self defaultVideoCompressionProperties] mutableCopy];
        [self updateSourceFrameRateInComprssionProperties];
    }
    return self;
}

#pragma mark - Properties

- (void)setFramesPerSecond:(NSUInteger)framesPerSecond {
    _framesPerSecond = framesPerSecond;
    [self updateSourceFrameRateInComprssionProperties];
}

- (void)setVideoCompressionProperties:(NSDictionary *)videoCompressionProperties {
    _videoCompressionProperties = [videoCompressionProperties ?: [self defaultVideoCompressionProperties] mutableCopy];
    [self updateSourceFrameRateInComprssionProperties];
}

#pragma mark - Private

- (void)updateSourceFrameRateInComprssionProperties {
    _videoCompressionProperties[AVVideoExpectedSourceFrameRateKey] = @(_framesPerSecond);
}

- (NSDictionary *)defaultVideoCompressionProperties {
    return @{
             AVVideoAverageBitRateKey      : @(kDefaultVideoBitRate),
             AVVideoProfileLevelKey        : AVVideoProfileLevelH264HighAutoLevel,
             AVVideoAllowFrameReorderingKey : @NO,
             AVVideoH264EntropyModeKey: AVVideoH264EntropyModeCABAC,
             };
}

@end
