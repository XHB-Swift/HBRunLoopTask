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
//    @"https://img.newyx.net/lol/skin/37a099c448.png",
//    @"https://cn.bing.com/th?id=OIP.C6Qb0Us_jqJeHg4b8tF9jAAAAA&pid=Api&rs=1",
   @"https://timgsa.baidu.com/timg?image&quality=80&size=b9999_10000&sec=1574364312169&di=2561bdb80e7f65ecc3783f658fa96df3&imgtype=0&src=http%3A%2F%2Fb-ssl.duitang.com%2Fuploads%2Fitem%2F201801%2F12%2F20180112185049_Wk4ZS.thumb.700_0.jpeg",
   @"https://timgsa.baidu.com/timg?image&quality=80&size=b9999_10000&sec=1574364116215&di=5dae6f422936c35dd3d71d5843bbe427&imgtype=0&src=http%3A%2F%2Fb-ssl.duitang.com%2Fuploads%2Fitem%2F201809%2F25%2F20180925215828_pkypn.thumb.224_0.jpg",
   @"https://timgsa.baidu.com/timg?image&quality=80&size=b9999_10000&sec=1574363911679&di=ee696d63f40824963da8595eb27b6ec4&imgtype=0&src=http%3A%2F%2Fb-ssl.duitang.com%2Fuploads%2Fitem%2F201801%2F12%2F20180112185109_KRHtr.jpeg",
   @"https://timgsa.baidu.com/timg?image&quality=80&size=b9999_10000&sec=1574363824456&di=93eb6e1bc80e835224901b3e0462b482&imgtype=0&src=http%3A%2F%2Fb-ssl.duitang.com%2Fuploads%2Fitem%2F201801%2F12%2F20180112185135_8ckVa.jpeg",
    @"https://timgsa.baidu.com/timg?image&quality=80&size=b9999_10000&sec=1574360670967&di=d384e9c2ba7a367e5618aa5ac1c0eafb&imgtype=0&src=http%3A%2F%2Fimg.duoziwang.com%2F2016%2F10%2F15%2F1507196324.jpg",
    @"https://timgsa.baidu.com/timg?image&quality=80&size=b9999_10000&sec=1574360713738&di=5e684f510aa2b757e85b9ed906ade8f9&imgtype=0&src=http%3A%2F%2Fimg2.touxiang.cn%2Ffile%2F20161222%2F59e2b783b97e301d880179b96269b95c.jpg",
    @"https://timgsa.baidu.com/timg?image&quality=80&size=b9999_10000&sec=1574360740760&di=d1a291b28aacd08408fc606ae158477e&imgtype=0&src=http%3A%2F%2Fwww.ghost64.com%2Fqqtupian%2FzixunImg%2Flocal%2F2017%2F07%2F25%2F15009601243359.jpg",
    @"https://timgsa.baidu.com/timg?image&quality=80&size=b9999_10000&sec=1574360807338&di=475894f254f6d6450b10801c9d6b2e36&imgtype=0&src=http%3A%2F%2Fimgup04.golue.com%2Fgolue%2F2019-11%2F11%2F10%2F15734382931318_4.jpg",
    @"https://timgsa.baidu.com/timg?image&quality=80&size=b9999_10000&sec=1574360825034&di=0c2c3b820bf6c5c8da50fdb3a983ddf7&imgtype=0&src=http%3A%2F%2Fimgup04.golue.com%2Fgolue%2F2019-11%2F11%2F10%2F15734382931318_6.jpg",
    @"https://timgsa.baidu.com/timg?image&quality=80&size=b9999_10000&sec=1574360837525&di=87097c68da2c6892fba62b68d3a1ebb6&imgtype=0&src=http%3A%2F%2Fimgup04.golue.com%2Fgolue%2F2019-11%2F11%2F10%2F15734382931318_2.jpg",
   @"https://timgsa.baidu.com/timg?image&quality=80&size=b9999_10000&sec=1574364191299&di=2ad14b7e6c840410026adb6faba3653c&imgtype=0&src=http%3A%2F%2Fb-ssl.duitang.com%2Fuploads%2Fitem%2F201810%2F25%2F20181025203107_gtiqs.jpg",
    ];
//    self.tbDataSource = [HBTableViewDataSource dataSourceWithImageURLs:imageURLs];
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
    [self.view addSubview:({
        
        UICollectionViewFlowLayout *flowLayout = [[UICollectionViewFlowLayout alloc] init];
        flowLayout.scrollDirection = UICollectionViewScrollDirectionVertical;
        flowLayout.sectionInset = (UIEdgeInsets){0,10,0,10};
        flowLayout.minimumInteritemSpacing = 10;
        flowLayout.minimumLineSpacing = 10;
        CGFloat length = (CGRectGetWidth(bounds) - 10*3) / 2;
        CGRect intRect = CGRectIntegral((CGRect){CGPointZero,(CGSize){length,length}});
        flowLayout.itemSize = intRect.size;
        UICollectionView *collectionView = [[UICollectionView alloc] initWithFrame:bounds collectionViewLayout:flowLayout];
        collectionView.backgroundColor = [UIColor whiteColor];
        [collectionView registerClass:[HBImageCollectionViewCell class] forCellWithReuseIdentifier:@"cvCellId"];
        self.cvDataSource = [HBCollectionViewDataSource dataSourceWithImageURLs:imageURLs collectionView:collectionView];
        self.cvDataSource.cellIdentifiers = @[@"cvCellId"];
        collectionView;
    })];
}


@end
