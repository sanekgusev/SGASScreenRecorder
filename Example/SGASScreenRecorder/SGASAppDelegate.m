//
//  SGASAppDelegate.m
//  SGASScreenRecorder
//
//  Created by CocoaPods on 10/22/2014.
//  Copyright (c) 2014 Alexander Gusev. All rights reserved.
//

#import "SGASAppDelegate.h"
#import "SGASTableViewController.h"

@interface SGASAppDelegate () {
    SGASTableViewController *_viewController;
}

@end

@implementation SGASAppDelegate

@synthesize window = _window;

- (BOOL)application:(UIApplication *)application didFinishLaunchingWithOptions:(NSDictionary *)launchOptions
{
    _window = [[UIWindow alloc] initWithFrame:[UIScreen mainScreen].bounds];
    _viewController = [SGASTableViewController new];
    _window.rootViewController = [[UINavigationController alloc] initWithRootViewController:_viewController];
    [_window makeKeyAndVisible];
    return YES;
}

@end
