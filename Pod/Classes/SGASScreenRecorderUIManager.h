//
//  SGASScreenRecorderUIManager.h
//  Pods
//
//  Created by Aleksandr Gusev on 23/10/14.
//
//

#import <UIKit/UIKit.h>

@interface SGASScreenRecorderUIManager : NSObject

@property (nonatomic, assign, getter=isEnabled) BOOL enabled;

- (instancetype)initWithScreenCorner:(UIRectCorner)screenCorner
                   overlayWindowSize:(CGSize)overlayWindowSize
               activationTapAreaSize:(CGSize)activationTapAreaSize NS_DESIGNATED_INITIALIZER;

- (instancetype)initWithScreenCorner:(UIRectCorner)screenCorner;

@end

