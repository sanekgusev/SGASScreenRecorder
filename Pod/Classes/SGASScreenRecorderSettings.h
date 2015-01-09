//
//  SGASScreenRecorderSettings.h
//  SGASScreenRecorder
//
//  Created by Shmatlay Andrey on 22.06.13.
//  
//

#import <Foundation/Foundation.h>

@interface SGASScreenRecorderSettings : NSObject

/// This dictionary will be passed as a value of AVVideoCompressionPropertiesKey
/// in the output settings dictionary of an AVAssetWriterInput instance.
@property (nonatomic, copy) NSDictionary *videoCompressionProperties;

/// Desired framerate. Doesn't make sense to specify values above 60.
@property (nonatomic, assign) NSUInteger framesPerSecond;

/// Maximum pixel dimension of the video. If either of the screen dimensions
/// is greater than this value, the output video will be proportionally scaled
/// so that neither width nor height exceed this value.
/// This is useful when importing videos to the Photo library, as it will
/// not allow videos above certain size (e.g. full-resolution Retina iPad captures).
@property (nonatomic, assign) NSUInteger maximumVideoDimension;

@end
