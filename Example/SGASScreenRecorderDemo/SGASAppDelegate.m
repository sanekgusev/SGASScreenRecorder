//
//  SGASAppDelegate.m
//  SGASScreenRecorder
//
//  Created by CocoaPods on 10/22/2014.
//  Copyright (c) 2014 Alexander Gusev. All rights reserved.
//

#import "SGASAppDelegate.h"
#import "SGASTableViewController.h"

NS_ASSUME_NONNULL_BEGIN

@implementation SGASAppDelegate

@synthesize window = _window;

- (BOOL)application:(UIApplication *)application didFinishLaunchingWithOptions:(nullable NSDictionary *)launchOptions {
    _window = [[UIWindow alloc] initWithFrame:[UIScreen mainScreen].bounds];
    SGASTableViewController *viewController = [[SGASTableViewController alloc] initWithStyle:UITableViewStyleGrouped];
    UINavigationController *navigationController = [[UINavigationController alloc] initWithRootViewController:viewController];
    if ([navigationController respondsToSelector:@selector(setHidesBarsOnSwipe:)]) {
        navigationController.hidesBarsOnSwipe = YES;
    }
    if ([navigationController respondsToSelector:@selector(setHidesBarsWhenVerticallyCompact:)]) {
        navigationController.hidesBarsWhenVerticallyCompact = YES;
    }
    if ([navigationController respondsToSelector:@selector(setHidesBarsWhenKeyboardAppears:)]) {
        navigationController.hidesBarsWhenKeyboardAppears = YES;
    }
    _window.rootViewController = navigationController;
    [_window makeKeyAndVisible];
    return YES;
}

@end

NS_ASSUME_NONNULL_END