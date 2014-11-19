//
//  SRMotionFingerView.m
//  ScreenRecorderHackaton
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
        self.windowLevel = UIWindowLevelStatusBar + 2.0f;
        self.backgroundColor = [UIColor clearColor];
        self.userInteractionEnabled = NO;
        [self sizeToFit];
    }
    return self;
}

- (instancetype)initWithFrame:(CGRect)frame {
    return [self init];
}

#pragma mark - UIWindow

#pragma mark - UIView

- (void)drawRect:(CGRect)rect {
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
    CGContextDrawRadialGradient(context, gradient, center, 0, center, CGRectGetWidth(rect) / 2.0f, kNilOptions);
    
    CGGradientRelease(gradient);
    CGColorSpaceRelease(colorSpace);
}

- (CGSize)sizeThatFits:(CGSize)size {
    return CGSizeMake(kDimension, kDimension);
}

@end
