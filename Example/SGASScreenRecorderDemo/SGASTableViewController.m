//
//  SGASViewController.m
//  SGASScreenRecorder
//
//  Created by Alexander Gusev on 10/22/2014.
//  Copyright (c) 2014 Alexander Gusev. All rights reserved.
//

#import "SGASTableViewController.h"
#import "SGASScreenRecorderUIManager.h"
#import "SGASWebViewController.h"

@interface SGASTableViewController () {
    SGASScreenRecorderUIManager *_screenRecorderUIManager;
    NSArray *_goodReadsTitles;
    NSDictionary *_goodReadsURLs;
}

@end

static NSString * const kSwitchCellReuseIdentifier = @"SwitchCell";
static NSString * const kGoodReadCellReuseIdentifier = @"GoodReadCell";

@implementation SGASTableViewController

#pragma mark - Init/dealloc

- (instancetype)initWithStyle:(UITableViewStyle)style {
    if (self = [super initWithStyle:style]) {
        [self initializeGoodReads];
        [self setupScreenRecorderUIManager];
        self.title = NSLocalizedString(@"SGASScreenRecorder", nil);
    }
    return self;
}

#pragma mark - UIViewController

- (void)viewDidLoad
{
    [super viewDidLoad];
    [self.tableView registerClass:[UITableViewCell class]
           forCellReuseIdentifier:kSwitchCellReuseIdentifier];
    [self.tableView registerClass:[UITableViewCell class]
           forCellReuseIdentifier:kGoodReadCellReuseIdentifier];
}

- (NSUInteger)supportedInterfaceOrientations {
    return UIInterfaceOrientationMaskAll;
}

#pragma mark - Actions

- (void)switchValueChanged:(UISwitch *)aSwitch {
    _screenRecorderUIManager.enabled = aSwitch.on;
}

#pragma mark - UITableViewDataSource

- (NSInteger)numberOfSectionsInTableView:(UITableView *)tableView {
    return 2;
}

- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section {
    if (section == 0) {
        return 1;
    }
    return (NSInteger)[_goodReadsTitles count];
}

- (UITableViewCell *)tableView:(UITableView *)tableView
         cellForRowAtIndexPath:(NSIndexPath *)indexPath {
    UITableViewCell *cell;
    if ([indexPath section] == 0) {
        cell = [tableView dequeueReusableCellWithIdentifier:kSwitchCellReuseIdentifier
                                               forIndexPath:indexPath];
        cell.selectionStyle = UITableViewCellSelectionStyleNone;
        if (!cell.accessoryView) {
            UISwitch *aSwitch = [UISwitch new];
            [aSwitch addTarget:self
                        action:@selector(switchValueChanged:)
              forControlEvents:UIControlEventValueChanged];
            cell.accessoryView = aSwitch;
        }
        cell.textLabel.text = NSLocalizedString(@"Screen Recorder Overlay", nil);
    }
    else {
        cell = [tableView dequeueReusableCellWithIdentifier:kGoodReadCellReuseIdentifier
                                               forIndexPath:indexPath];
        cell.accessoryType = UITableViewCellAccessoryDisclosureIndicator;
        cell.textLabel.text = _goodReadsTitles[(NSUInteger)[indexPath row]];
    }
    return cell;
}

- (NSString *)tableView:(UITableView *)tableView titleForFooterInSection:(NSInteger)section {
    return section == 0 ? NSLocalizedString(@"Triple tap the overlay square to record", nil) : nil;
}

- (NSString *)tableView:(UITableView *)tableView titleForHeaderInSection:(NSInteger)section {
    return section == 0 ? nil : NSLocalizedString(@"Some Good Reads", nil);
}

#pragma mark - UITableViewDelegate

- (NSIndexPath *)tableView:(UITableView *)tableView willSelectRowAtIndexPath:(NSIndexPath *)indexPath {
    return [indexPath section] == 0 ? nil : indexPath;
}

- (void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath {
    if ([indexPath section] != 0) {
        NSURL *url = _goodReadsURLs[_goodReadsTitles[(NSUInteger)[indexPath row]]];
        [self.navigationController pushViewController:[[SGASWebViewController alloc] initWithURL:url]
                                             animated:YES];
    }
}

#pragma mark - Private

- (void)initializeGoodReads {
    _goodReadsTitles = @[@"objc.io",
                         @"NSHipster",
                         @"NSBlog"];
    _goodReadsURLs = @{@"objc.io": [NSURL URLWithString:@"http://www.objc.io"],
                       @"NSHipster": [NSURL URLWithString:@"http://nshipster.com"],
                       @"NSBlog": [NSURL URLWithString:@"https://www.mikeash.com/pyblog/"]};
}

- (void)setupScreenRecorderUIManager {
    SGASScreenRecorderSettings *settings = [SGASScreenRecorderSettings new];
    _screenRecorderUIManager = [[SGASScreenRecorderUIManager alloc] initWithScreenCorner:UIRectCornerTopLeft
                                                                  screenRecorderSettings:settings];
}

@end
