//
//  SGASWebViewController.h
//  SGASScreenRecorder
//
//  Created by Aleksandr Gusev on 12/14/14.
//  Copyright (c) 2014 Alexander Gusev. All rights reserved.
//

#import <UIKit/UIKit.h>

@interface SGASWebViewController : UIViewController

@property (nonatomic, readonly) NSURL *url;

- (instancetype)initWithURL:(NSURL *)url NS_DESIGNATED_INITIALIZER;

@end
