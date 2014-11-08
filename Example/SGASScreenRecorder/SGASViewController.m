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

@end

@implementation SGASViewController

- (void)viewDidLoad
{
    [super viewDidLoad];
	// Do any additional setup after loading the view, typically from a nib.
}

- (void)didReceiveMemoryWarning
{
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}
- (IBAction)toggleButtonAction {
    [SGASScreenRecorderUIManager sharedManager].enabled = ![SGASScreenRecorderUIManager sharedManager].enabled;
}

@end
