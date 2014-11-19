//
//  SGASViewController.m
//  SGASScreenRecorder
//
//  Created by Alexander Gusev on 10/22/2014.
//  Copyright (c) 2014 Alexander Gusev. All rights reserved.
//

#import "SGASViewController.h"
#import "SGASScreenRecorderUIManager.h"

@interface SGASViewController () {
    
}

@property (nonatomic, strong) IBOutlet UIWebView *webView;

@end

@implementation SGASViewController

- (void)viewDidLoad
{
    [super viewDidLoad];
	// Do any additional setup after loading the view, typically from a nib.
}

- (void)viewDidAppear:(BOOL)animated {
    [super viewDidAppear:animated];
    [_webView loadRequest:[NSURLRequest requestWithURL:[NSURL URLWithString:@"http://www.theverge.com"]]];
}

- (NSUInteger)supportedInterfaceOrientations {
    return UIInterfaceOrientationMaskAll;
}

- (BOOL)shouldAutorotate {
    return YES;
}

- (IBAction)toggleButtonAction {
    [SGASScreenRecorderUIManager sharedManager].enabled = ![SGASScreenRecorderUIManager sharedManager].enabled;
}

@end
