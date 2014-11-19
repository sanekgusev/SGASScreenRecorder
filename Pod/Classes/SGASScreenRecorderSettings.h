//
//  SRRecorderSettings.h
//  ScreenRecorderHackaton
//
//  Created by Shmatlay Andrey on 22.06.13.
//  Copyright (c) 2013 Shmatlay Andrey. All rights reserved.
//

#import <Foundation/Foundation.h>

@interface SGASScreenRecorderSettings : NSObject
@property (nonatomic, copy) NSDictionary *compressionSettings;
@property (nonatomic, assign) NSInteger framesPerSecond;
@property (nonatomic, assign) NSUInteger maximumOutputVideoDimension;

@end
