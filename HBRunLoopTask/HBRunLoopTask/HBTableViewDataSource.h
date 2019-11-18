//
//  HBTableViewDataSource.h
//  HBRunLoopTask
//
//  Created by 谢鸿标 on 2019/11/15.
//  Copyright © 2019 谢鸿标. All rights reserved.
//

#import <UIKit/UIKit.h>

NS_ASSUME_NONNULL_BEGIN

@interface HBTableViewDataSource : NSObject <UITableViewDataSource>

@property (nonatomic, copy) NSArray<NSString *> *cellIdentifiers;

@property (nonatomic, weak) UITableView *tableView;

+ (instancetype)dataSourceWithImageURLs:(NSArray<NSString *> *)imageURLs;

- (instancetype)initWithImageURLs:(NSArray<NSString *> *)imageURLs;

//网络请求单独放在一个线程操作
- (void)loadNetworkImages;

@end

NS_ASSUME_NONNULL_END
