//
//  ViewController.m
//  HBRunLoopTask
//
//  Created by 谢鸿标 on 2019/11/13.
//  Copyright © 2019 谢鸿标. All rights reserved.
//

#import "ViewController.h"
#import "HBTableViewDataSource.h"
#import "HBCollectionViewDataSource.h"

@interface ViewController ()

@property (nonatomic, strong) HBTableViewDataSource *tbDataSource;
@property (nonatomic, strong) HBCollectionViewDataSource *cvDataSource;

@end

@implementation ViewController


- (void)viewDidLoad {
    [super viewDidLoad];
    
    NSArray<NSString *> *imageURLs = @[
    @"https://img.newyx.net/lol/skin/37a099c448.png",
    @"https://cn.bing.com/th?id=OIP.C6Qb0Us_jqJeHg4b8tF9jAAAAA&pid=Api&rs=1",
    @"https://img.newyx.net/lol/skin/37a099c448.png",
    @"https://cn.bing.com/th?id=OIP.C6Qb0Us_jqJeHg4b8tF9jAAAAA&pid=Api&rs=1"
    ];
//    self.tbDataSource = [HBTableViewDataSource dataSourceWithImageURLs:imageURLs];
    self.cvDataSource = [HBCollectionViewDataSource dataSourceWithImageURLs:imageURLs];
    CGRect bounds = self.view.frame;
//    self.tbDataSource.cellIdentifiers = @[@"cellId"];
//    [self.view addSubview:({
//        UITableView *tableView = [[UITableView alloc] initWithFrame:bounds style:(UITableViewStylePlain)];
//        tableView.dataSource = self.tbDataSource;
//        [tableView registerClass:[UITableViewCell class] forCellReuseIdentifier:@"cellId"];
//        tableView.rowHeight = 130;
//        self.tbDataSource.tableView = tableView;
//        tableView;
//    })];
//
//    dispatch_after(dispatch_time(DISPATCH_TIME_NOW, (int64_t)(4 * NSEC_PER_SEC)), dispatch_get_main_queue(), ^{
//        [self.tbDataSource loadNetworkImages];
//    });
    self.cvDataSource.cellIdentifiers = @[@"cvCellId"];
    [self.view addSubview:({
        
        UICollectionViewFlowLayout *flowLayout = [[UICollectionViewFlowLayout alloc] init];
        flowLayout.scrollDirection = UICollectionViewScrollDirectionVertical;
        flowLayout.sectionInset = (UIEdgeInsets){0,10,0,10};
        flowLayout.minimumInteritemSpacing = 5;
        flowLayout.minimumLineSpacing = 5;
        UICollectionView *collectionView = [[UICollectionView alloc] initWithFrame:bounds collectionViewLayout:flowLayout];
        collectionView.backgroundColor = [UIColor whiteColor];
        collectionView.dataSource = self.cvDataSource;
        collectionView.delegate = self.cvDataSource;
        [collectionView registerClass:[HBImageCollectionViewCell class] forCellWithReuseIdentifier:@"cvCellId"];
        self.cvDataSource.collectionView = collectionView;
        collectionView;
    })];
}


@end
