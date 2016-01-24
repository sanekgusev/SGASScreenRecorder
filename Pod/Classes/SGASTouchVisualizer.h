//
//  SGASTouchVisualizer.h
//  SGASScreenRecorder
//
//  Created by Aleksandr Gusev on 23/10/14.
//
//

#import <Foundation/Foundation.h>

NS_ASSUME_NONNULL_BEGIN

@interface SGASTouchVisualizer : NSObject

@property (nonatomic, assign) BOOL visualizesTouches;

+ (instancetype)sharedVisualizer;

@end

NS_ASSUME_NONNULL_END