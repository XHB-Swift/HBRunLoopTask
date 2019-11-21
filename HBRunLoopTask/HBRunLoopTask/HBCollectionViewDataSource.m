//
//  HBCollectionViewDataSource.m
//  HBRunLoopTask
//
//  Created by 谢鸿标 on 2019/11/21.
//  Copyright © 2019 谢鸿标. All rights reserved.
//

#import "HBCollectionViewDataSource.h"
#import "HBRunLoopTask.h"
#import "HBRunLoopTaskManager.h"
#import "HBImageModel.h"


@implementation HBImageCollectionViewCell

- (instancetype)initWithFrame:(CGRect)frame {
    if (self = [super initWithFrame:frame]) {
        CGRect rect = self.contentView.bounds;
        UIImageView *imageView = [[UIImageView alloc] initWithFrame:rect];
        imageView.tag = 10903;
        [self.contentView addSubview:imageView];
    }
    return self;
}

- (void)setImage:(UIImage *)image {
    UIImageView *imageView = [self.contentView viewWithTag:10903];
    imageView.image = image;
    if (CGRectEqualToRect(imageView.frame, CGRectZero)) {
        imageView.frame = self.contentView.bounds;
    }
}

- (UIImage *)image {
    UIImageView *imageView = [self.contentView viewWithTag:10903];
    return imageView.image;
}

@end

@interface HBCollectionViewDataSource ()

@property (nonatomic, strong) HBRunLoopTaskManager *taskManager;
@property (nonatomic, strong) NSMutableArray<HBImageModel *> *imageModels;

@end

@implementation HBCollectionViewDataSource

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
    if (identifier) {
        cell = [collectionView dequeueReusableCellWithReuseIdentifier:identifier forIndexPath:indexPath];
        cell.image = model.cachedImage;
    }
    return cell;
}

- (void)runLoopDownLoadImageAction:(HBImageModel *)model {
    if (!model.imageData) {
        model.imageData = [NSData dataWithContentsOfURL:model.imageURL];
    }
}

- (void)runLoopDecodeImageAction:(HBImageModel *)model {
    if (!model.cachedImage) {
        [model decodeImage];
        dispatch_async(dispatch_get_main_queue(), ^{
            [self.collectionView performBatchUpdates:^{
                NSArray<NSIndexPath *> *reloadIndexPaths = @[model.indexPath];
                [self.collectionView reloadItemsAtIndexPaths:reloadIndexPaths];
                UICollectionViewFlowLayoutInvalidationContext *invalidateCtx = [[UICollectionViewFlowLayoutInvalidationContext alloc] init];
                [invalidateCtx invalidateItemsAtIndexPaths:reloadIndexPaths];
                [self.collectionView.collectionViewLayout invalidateLayoutWithContext:invalidateCtx];
            } completion:nil];
        });
    }
}

- (CGSize)collectionView:(UICollectionView *)collectionView layout:(UICollectionViewLayout *)collectionViewLayout sizeForItemAtIndexPath:(NSIndexPath *)indexPath {
    HBImageModel *model = self.imageModels[indexPath.item];
    model.indexPath = indexPath;
    if (CGSizeEqualToSize(model.imageSize, CGSizeZero)) {
        //添加一个下载图片的任务
        HBRunLoopTask *downloadTask = [HBRunLoopTask runLoopTaskWithIdentifier:[NSString stringWithFormat:@"%@-download",indexPath] target:self action:@selector(runLoopDownLoadImageAction:) object:model];
        //添加一个解压缩图片任务
        HBRunLoopTask *decodeTask = [HBRunLoopTask runLoopTaskWithIdentifier:[NSString stringWithFormat:@"%@-decode",indexPath] target:self action:@selector(runLoopDecodeImageAction:) object:model];
        [self.taskManager addTasks:@[downloadTask,decodeTask]];
    }
    return model.imageSize;
}

@end
