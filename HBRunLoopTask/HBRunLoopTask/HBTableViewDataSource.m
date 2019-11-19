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

@interface HBTableViewCellImageModel : NSObject

@property (nonatomic, strong) NSIndexPath *indexPath;
@property (nonatomic, readonly, copy) NSURL *imageURL;
@property (nonatomic, nullable, copy) NSData *imageData;
@property (nonatomic, nullable, copy, readonly) UIImage *cachedImage;

+ (instancetype)imageModelWithImageURL:(NSString *)imageURL;

@end

@implementation HBTableViewCellImageModel

+ (instancetype)imageModelWithImageURL:(NSString *)imageURL {
    if (imageURL) {
        NSURL *URL = [NSURL URLWithString:imageURL];
        return [[HBTableViewCellImageModel alloc] initWithImageURL:URL];
    }else {
        return nil;
    }
}

- (instancetype)initWithImageURL:(NSURL *)imageURL {
    if (self = [super init]) {
        _imageURL = [imageURL copy];
    }
    return self;
}

- (void)decodeImage {
    if (!_cachedImage) {
        if (_imageData) {
            UIImage *originalImage = [UIImage imageWithData:_imageData];
            CGImageRef imageRef = originalImage.CGImage;
            size_t width = CGImageGetWidth(imageRef);
            size_t height = CGImageGetHeight(imageRef);
            CGColorSpaceRef colorSpace = CGImageGetColorSpace(imageRef);
            size_t bitsPerComponent = CGImageGetBitsPerComponent(imageRef);
            size_t bitsPerPixel = CGImageGetBitsPerPixel(imageRef);
            size_t bytesPerRow = CGImageGetBytesPerRow(imageRef);
            CGBitmapInfo bitmapInfo = CGImageGetBitmapInfo(imageRef);
            CGDataProviderRef dataProvider = CGImageGetDataProvider(imageRef);
            CFDataRef data = CGDataProviderCopyData(dataProvider);
            CGDataProviderRef newDataProvider = CGDataProviderCreateWithCFData(data);
            CFRelease(data);
            CGImageRef newImageRef = CGImageCreate(width, height, bitsPerComponent, bitsPerPixel, bytesPerRow, colorSpace, bitmapInfo, newDataProvider, NULL, false, kCGRenderingIntentDefault);
            CFRelease(newDataProvider);
            _cachedImage = [[UIImage alloc] initWithCGImage:newImageRef];
            CGImageRelease(newImageRef);
        }
    }
}

@end

@interface HBTableViewDataSource ()

@property (nonatomic, strong) HBRunLoopTaskManager *taskManager;
@property (nonatomic, strong) NSMutableArray<HBTableViewCellImageModel *> *imageModels;

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
                HBTableViewCellImageModel *model = [HBTableViewCellImageModel imageModelWithImageURL:url];
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
    HBTableViewCellImageModel *model = self.imageModels[indexPath.row];
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

- (void)runLoopTaskWithObject:(HBTableViewCellImageModel *)object {
    object.imageData = [NSData dataWithContentsOfURL:object.imageURL];
    [object decodeImage];
    dispatch_async(dispatch_get_main_queue(), ^{
        [self.tableView reloadRowsAtIndexPaths:@[object.indexPath] withRowAnimation:(UITableViewRowAnimationAutomatic)];
    });
}

@end
