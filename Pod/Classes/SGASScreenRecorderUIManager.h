//
//  SGASScreenRecorderUIManager.h
//  Pods
//
//  Created by Aleksandr Gusev on 23/10/14.
//
//

#import <Foundation/Foundation.h>

@interface SGASScreenRecorderUIManager : NSObject

@property (nonatomic, assign) BOOL enabled;

+ (instancetype)sharedManager;

@end

