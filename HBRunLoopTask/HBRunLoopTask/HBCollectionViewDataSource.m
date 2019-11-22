//
//  HBCollectionViewDataSource.m
//  HBRunLoopTask
//
//  Created by 谢鸿标 on 2019/11/21.
//  Copyright © 2019 谢鸿标. All rights reserved.
//

#import "HBCollectionViewDataSource.h"
#import "HBRunLoopTask.h"
#import "HBRunLoopTaskThread.h"
#import "HBImageModel.h"


@implementation HBImageCollectionViewCell

- (void)setImage:(UIImage *)image {
    self.contentView.layer.contents = (id)image.CGImage;
}

@end

@interface HBCollectionViewDataSource ()

@property (nonatomic, weak) UICollectionView *collectionView;
@property (nonatomic, strong) HBRunLoopTaskThread *taskManager;
@property (nonatomic, strong) NSMutableArray<HBImageModel *> *imageModels;

@end

@implementation HBCollectionViewDataSource

+ (instancetype)dataSourceWithImageURLs:(NSArray<NSString *> *)imageURLs collectionView:(UICollectionView *)collectionView {
    return [[HBCollectionViewDataSource alloc] initWithImageURLs:imageURLs collectionView:collectionView];
}

- (instancetype)initWithImageURLs:(NSArray<NSString *> *)imageURLs collectionView:(UICollectionView *)collectionView {
    if (self = [super init]) {
        collectionView.dataSource = self;
        collectionView.delegate = self;
        _collectionView = collectionView;
        UICollectionViewFlowLayout *flowlayout = (UICollectionViewFlowLayout *)collectionView.collectionViewLayout;
        CGSize itemSize = flowlayout.itemSize;
        _imageModels = [NSMutableArray array];
       if (imageURLs) {
           [imageURLs enumerateObjectsUsingBlock:^(NSString * _Nonnull url, NSUInteger idx, BOOL * _Nonnull stop) {
               HBImageModel *model = [HBImageModel imageModelWithImageURL:url thumbnailImageSize:itemSize];
               [_imageModels addObject:model];
           }];
       }
       _taskManager = [HBRunLoopTaskThread runLoopTaskThread];
       _taskManager.shouldExecuteTaskImmediately = YES;
       _taskManager.maxContainerTaskCount = 10;
       _taskManager.maxExecutionTaskCount = 1;
    }
    return self;
}

- (NSInteger)numberOfSectionsInCollectionView:(UICollectionView *)collectionView {
    return 1;
}

- (NSInteger)collectionView:(UICollectionView *)collectionView numberOfItemsInSection:(NSInteger)section {
    return self.imageModels.count;
}

- (UICollectionViewCell *)collectionView:(UICollectionView *)collectionView cellForItemAtIndexPath:(NSIndexPath *)indexPath {
    
    NSString *identifier = self.cellIdentifiers.firstObject;
    HBImageCollectionViewCell *cell = nil;
    HBImageModel *model = self.imageModels[indexPath.item];
    model.indexPath = indexPath;
    if (identifier) {
        cell = [collectionView dequeueReusableCellWithReuseIdentifier:identifier forIndexPath:indexPath];
        if (!model.thumbnailImage) {
            //添加一个下载图片解压缩图片任务
            NSString *taskIdentifier = [NSString stringWithFormat:@"%@-decode",indexPath];
            HBRunLoopTask *task = [HBRunLoopTask runLoopTaskWithIdentifier:taskIdentifier target:self action:@selector(runLoopDownloadAndDecodeImageAction:) object:model];
            [self.taskManager addTask:task];
        }else {
            cell.image = model.thumbnailImage;
        }
    }
    return cell;
}

- (void)runLoopDownloadAndDecodeImageAction:(HBImageModel *)model {
    if (!model.cachedImage) {
        if (!model.imageData) {
            model.imageData = [NSData dataWithContentsOfURL:model.imageURL];
        }
        [model decodeImage];
        [model createThumbnailImageIfNeeded];
        dispatch_async(dispatch_get_main_queue(), ^{
            [self.collectionView performBatchUpdates:^{
                NSArray<NSIndexPath *> *reloadIndexPaths = @[model.indexPath];
                [self.collectionView reloadItemsAtIndexPaths:reloadIndexPaths];
            } completion:nil];
        });
    }
}

@end
