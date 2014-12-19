//
//  SGASAppDelegate.m
//  SGASScreenRecorder
//
//  Created by CocoaPods on 10/22/2014.
//  Copyright (c) 2014 Alexander Gusev. All rights reserved.
//

#import "SGASAppDelegate.h"
#import "SGASTableViewController.h"

@implementation SGASAppDelegate

@synthesize window = _window;

- (BOOL)application:(UIApplication *)application didFinishLaunchingWithOptions:(NSDictionary *)launchOptions {
    _window = [[UIWindow alloc] initWithFrame:[UIScreen mainScreen].bounds];
    SGASTableViewController *viewController = [SGASTableViewController new];
    UINavigationController *navigationController = [[UINavigationController alloc] initWithRootViewController:viewController];
    navigationController.toolbarHidden = NO;
    _window.rootViewController = navigationController;
    [_window makeKeyAndVisible];
    return YES;
}

@end
