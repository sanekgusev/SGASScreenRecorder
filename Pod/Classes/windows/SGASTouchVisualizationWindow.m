//
//  SGASTouchVisualizationWindow.m
//  SGASScreenRecorder
//
//  Created by Shmatlay Andrey on 21.06.13.
//  Edited by Aleksandr Gusev on 23/10/14
//

#import "SGASTouchVisualizationWindow.h"

static CGFloat const kDimension = 44.0f;

@implementation SGASTouchVisualizationWindow

#pragma mark - Init/dealloc
- (id)init {
    self = [super initWithFrame:CGRectZero];
    if (self) {
        [self sizeToFit];
    }
    return self;
}

- (instancetype)initWithFrame:(CGRect)frame {
    return [self init];
}

#pragma mark - UIWindow 

- (UIViewController *)rootViewController {
    UIWindow *mainWindow = [UIApplication sharedApplication].delegate.window ?:
    [[UIApplication sharedApplication].windows firstObject];
    return mainWindow.rootViewController;
}

- (UIWindowLevel)windowLevel {
    return UIWindowLevelStatusBar + 2.0f;
}

#pragma mark - UIView

- (UIColor *)backgroundColor {
    return [UIColor clearColor];
}

- (BOOL)isUserInteractionEnabled {
    return NO;
}

- (void)layoutSubviews {
    // This is a pretty questionable approach...
    // but it works better than overriding -drawRect and just doing gradient drawing there
    // because for *some* reason, a hidden (but not deallocated) window whose contents are
    // drawn that way would still remain visible for some time on screen snapshots.
    // By using this approach we can cache and reuse touch windows without them remaining on
    // screen snapshots long after the touch has ended.
    [self recreateImage];
}

- (CGSize)sizeThatFits:(CGSize)size {
    return CGSizeMake(kDimension, kDimension);
}

#pragma mark - Private

- (void)recreateImage {
    CGRect rect = self.bounds;
    UIGraphicsBeginImageContextWithOptions(rect.size,
                                           NO,
                                           0.0f);
    CGContextRef context = UIGraphicsGetCurrentContext();
    CGColorSpaceRef colorSpace = CGColorSpaceCreateDeviceRGB();
    NSArray* colors = @[(id)[[UIColor blackColor] colorWithAlphaComponent:0.5f].CGColor,
                        (id)[[UIColor blackColor] colorWithAlphaComponent:0.5f].CGColor,
                        (id)[[UIColor whiteColor] colorWithAlphaComponent:0.5f].CGColor,
                        (id)[[UIColor whiteColor] colorWithAlphaComponent:0.5f].CGColor,
                        (id)[UIColor clearColor].CGColor,
                        (id)[UIColor clearColor].CGColor,
                        (id)[[UIColor blackColor] colorWithAlphaComponent:0.5f].CGColor,
                        (id)[[UIColor blackColor] colorWithAlphaComponent:0.5f].CGColor,
                        (id)[[UIColor whiteColor] colorWithAlphaComponent:0.5f].CGColor,
                        (id)[[UIColor whiteColor] colorWithAlphaComponent:0.5f].CGColor];
    CGFloat locations[] = {0.0f, 0.1f, 0.101f, 0.2f, 0.201f, 0.8f, 0.801f, 0.9f, 0.901f, 1.0f};
    CGGradientRef gradient = CGGradientCreateWithColors(colorSpace, (__bridge CFArrayRef)colors, locations);
    CGPoint center = CGPointMake(CGRectGetMidX(rect),
                                 CGRectGetMidY(rect));
    CGContextDrawRadialGradient(context, gradient, center, 0, center, CGRectGetWidth(rect) / 2.0f, (CGGradientDrawingOptions)0);
    self.layer.contents = (__bridge_transfer id)CGBitmapContextCreateImage(context);
    
    CGGradientRelease(gradient);
    CGColorSpaceRelease(colorSpace);
    UIGraphicsEndImageContext();
}

@end
