//
//  SGASScreenRecorderUIManager.h
//  SGASScreenRecorder
//
//  Created by Aleksandr Gusev on 23/10/14.
//
//

#import <UIKit/UIKit.h>
#import "SGASScreenRecorderSettings.h"

@interface SGASScreenRecorderUIManager : NSObject

@property (nonatomic, assign, getter=isEnabled) BOOL enabled;

- (instancetype)initWithScreenCorner:(UIRectCorner)screenCorner
                   overlayWindowSize:(CGSize)overlayWindowSize
               activationTapAreaSize:(CGSize)activationTapAreaSize
              screenRecorderSettings:(SGASScreenRecorderSettings *)settings NS_DESIGNATED_INITIALIZER;

- (instancetype)initWithScreenCorner:(UIRectCorner)screenCorner
              screenRecorderSettings:(SGASScreenRecorderSettings *)settings;

@end

