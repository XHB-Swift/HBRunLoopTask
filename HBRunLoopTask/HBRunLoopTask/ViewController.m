//
//  ViewController.m
//  HBRunLoopTask
//
//  Created by 谢鸿标 on 2019/11/13.
//  Copyright © 2019 谢鸿标. All rights reserved.
//

#import "ViewController.h"
#import "HBTableViewDataSource.h"

@interface ViewController ()

@property (nonatomic, strong) HBTableViewDataSource *dataSource;

@end

@implementation ViewController


- (void)viewDidLoad {
    [super viewDidLoad];
    
    self.dataSource = [HBTableViewDataSource dataSourceWithImageURLs:@[
        @"https://img.newyx.net/lol/skin/37a099c448.png",
        @"https://cn.bing.com/th?id=OIP.C6Qb0Us_jqJeHg4b8tF9jAAAAA&pid=Api&rs=1",
        @"https://img.newyx.net/lol/skin/37a099c448.png",
        @"https://cn.bing.com/th?id=OIP.C6Qb0Us_jqJeHg4b8tF9jAAAAA&pid=Api&rs=1"]];
    self.dataSource.cellIdentifiers = @[@"cellId"];
    CGRect bounds = self.view.frame;
    [self.view addSubview:({
        UITableView *tableView = [[UITableView alloc] initWithFrame:bounds style:(UITableViewStylePlain)];
        tableView.dataSource = self.dataSource;
        [tableView registerClass:[UITableViewCell class] forCellReuseIdentifier:@"cellId"];
        tableView.rowHeight = 130;
        self.dataSource.tableView = tableView;
        tableView;
    })];
    [self.dataSource loadNetworkImages];
}


@end
