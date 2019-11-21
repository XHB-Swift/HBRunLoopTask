//
//  HBTableViewDataSource.m
//  HBRunLoopTask
//
//  Created by 谢鸿标 on 2019/11/15.
//  Copyright © 2019 谢鸿标. All rights reserved.
//

#import "HBTableViewDataSource.h"
#import "HBRunLoopTask.h"
#import "HBRunLoopTaskManager.h"
#import "HBImageModel.h"

@interface HBTableViewDataSource ()

@property (nonatomic, strong) HBRunLoopTaskManager *taskManager;
@property (nonatomic, strong) NSMutableArray<HBImageModel *> *imageModels;

@end

@implementation HBTableViewDataSource

+ (instancetype)dataSourceWithImageURLs:(NSArray<NSString *> *)imageURLs {
    return [[self alloc] initWithImageURLs:imageURLs];
}

- (instancetype)initWithImageURLs:(NSArray<NSString *> *)imageURLs {
    if (self = [super init]) {
        _imageModels = [NSMutableArray array];
        if (imageURLs) {
            [imageURLs enumerateObjectsUsingBlock:^(NSString * _Nonnull url, NSUInteger idx, BOOL * _Nonnull stop) {
                HBImageModel *model = [HBImageModel imageModelWithImageURL:url];
                [_imageModels addObject:model];
            }];
        }
        _taskManager = [HBRunLoopTaskManager permanentThreadTaskManager];
        _taskManager.shouldExecuteTaskImmediately = NO;
        _taskManager.maxContainerTaskCount = 10;
        _taskManager.maxExecutionTaskCount = 1;
    }
    return self;
}

- (NSInteger)numberOfSectionsInTableView:(UITableView *)tableView {
    return 1;
}

- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section {
    return self.imageModels.count;
}

- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath {
    NSString *cellIdentifier = self.cellIdentifiers.firstObject;
    HBImageModel *model = self.imageModels[indexPath.row];
    model.indexPath = indexPath;
    UITableViewCell *cell = nil;
    if (cellIdentifier) {
        cell = [tableView dequeueReusableCellWithIdentifier:cellIdentifier forIndexPath:indexPath];
        if (!model.cachedImage) {
            HBRunLoopTask *task = [HBRunLoopTask runLoopTaskWithTarget:self action:@selector(runLoopTaskWithObject:) object:model];
            [self.taskManager addTask:task];
        }else {
            cell.imageView.image = model.cachedImage;
        }
    }
    return cell;
}

- (void)loadNetworkImages {
    [self.taskManager wakeupRunLoop];
}

#pragma mark - RunLoop负责下载以及解压图片任务

- (void)runLoopTaskWithObject:(HBImageModel *)object {
    object.imageData = [NSData dataWithContentsOfURL:object.imageURL];
    [object decodeImage];
    dispatch_async(dispatch_get_main_queue(), ^{
        [self.tableView reloadRowsAtIndexPaths:@[object.indexPath] withRowAnimation:(UITableViewRowAnimationAutomatic)];
    });
}

@end
