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
        [self sizeToFit];
    }
    return self;
}

- (instancetype)initWithFrame:(CGRect)frame {
    return [self init];
}

#pragma mark - UIView

- (void)drawRect:(CGRect)rect {
    CGContextRef context = UIGraphicsGetCurrentContext();
    CGColorSpaceRef colorSpace = CGColorSpaceCreateDeviceRGB();
    NSArray* colors = @[(id)[[UIColor whiteColor] colorWithAlphaComponent:0.5f].CGColor,
                        (id)[[UIColor whiteColor] colorWithAlphaComponent:0.5f].CGColor,
                        (id)[[UIColor darkGrayColor] colorWithAlphaComponent:0.4f].CGColor,
                        (id)[[UIColor darkGrayColor] colorWithAlphaComponent:0.4f].CGColor,
                        (id)[[UIColor lightGrayColor] colorWithAlphaComponent:0.4f].CGColor,
                        (id)[[UIColor lightGrayColor] colorWithAlphaComponent:0.4f].CGColor,
                        (id)[[UIColor grayColor] colorWithAlphaComponent:0.4f].CGColor,
                        (id)[[UIColor grayColor] colorWithAlphaComponent:0.3f].CGColor];
    CGFloat locations[] = {0.0f, 0.03f, 0.04f, 0.33f, 0.34f, 0.66f, 0.67f, 1.0f};
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
