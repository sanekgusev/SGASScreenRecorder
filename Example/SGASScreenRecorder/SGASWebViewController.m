//
//  SGASWebViewController.m
//  SGASScreenRecorder
//
//  Created by Aleksandr Gusev on 12/14/14.
//  Copyright (c) 2014 Alexander Gusev. All rights reserved.
//

#import "SGASWebViewController.h"

@interface SGASWebViewController () <UIWebViewDelegate> {
    UIWebView *_webView;
}

@end

@implementation SGASWebViewController

#pragma mark - Init/dealloc

- (instancetype)initWithURL:(NSURL *)url {
    NSCParameterAssert(url);
    if (!url) {
        return nil;
    }
    if (self = [super initWithNibName:nil bundle:nil]) {
        _url = url;
    }
    return self;
}

- (void)loadView {
    _webView = [UIWebView new];
    _webView.delegate = self;
    self.view = _webView;
}

- (void)viewWillAppear:(BOOL)animated {
    [super viewWillAppear:animated];
    if ([self isMovingToParentViewController]) {
        [_webView loadRequest:[[NSURLRequest alloc] initWithURL:_url]];
    }
}

- (NSUInteger)supportedInterfaceOrientations {
    return UIInterfaceOrientationMaskAll;
}

#pragma mark - UIWebViewDelegate

- (void)webViewDidFinishLoad:(UIWebView *)webView {
    self.title = [webView stringByEvaluatingJavaScriptFromString:@"document.title"];
}

@end
