# HBRunLoopTask
基于CFRunLoopRef，CFRunLoopSourceRef，CFRunLoopObserverRef封装的一个任务调度管理类。所有任务放到线程的RunLoop中可以根据设置，决定RunLoop一次可以执行几个任务
## Usage
``` Objective-C
#import "HBRunLoopTask.h"
#import "HBRunLoopTaskThread.h"

//创建一个RunLoop任务线程
HBRunLoopTaskThread *taskManager = [HBRunLoopTaskThread runLoopTaskThread];
//设置容器的最大任务数，超出的任务会被抛弃
taskManager.maxContainerTaskCount = 10;
//设置RunLoop可以执行的最大任务数
taskManager.maxExecutionTaskCount = 1;
//创建一个任务并且加入到管理器
HBRunLoopTask *task = [HBRunLoopTask runLoopTaskWithTarget:self action:@selector(runLoopTaskWithObject:) object:model];
//加入到管理期的任务会在RunLoop被唤醒时执行，外部无需理会
[taskManager addTask:task];
```
## Example
以下是UITableView中，cell要显示来自网络的，需要解压缩的图片例子部分代码，详见工程源码

1、图片模型
``` Objective-C

//图片模型
@interface HBImageModel : NSObject

@property (nonatomic, strong) NSIndexPath *indexPath;
@property (nonatomic, readonly) CGSize imageSize;
@property (nonatomic, readonly) CGSize thumbnailImageSize;
@property (nonatomic, readonly, copy) NSURL *imageURL;
@property (nonatomic, nullable, copy) NSData *imageData;
@property (nonatomic, nullable, strong, readonly) UIImage *cachedImage;
@property (nonatomic, nullable, strong, readonly) UIImage *thumbnailImage;

+ (instancetype _Nullable)imageModelWithImageURL:(NSString *)imageURL;

+ (instancetype _Nullable)imageModelWithImageURL:(NSString *)imageURL thumbnailImageSize:(CGSize)thumbnailImageSize;

- (void)decodeImage;

- (void)createThumbnailImageIfNeeded;

@end

@implementation HBImageModel

+ (instancetype _Nullable)imageModelWithImageURL:(NSString *)imageURL {
    if (imageURL) {
        NSURL *URL = [NSURL URLWithString:imageURL];
        return [[HBImageModel alloc] initWithImageURL:URL];
    }else {
        return nil;
    }
}

- (instancetype)initWithImageURL:(NSURL *)imageURL {
    return [self initWithImageURL:imageURL thumbnailImageSize:(CGSize){150,150}];
}

+ (instancetype _Nullable)imageModelWithImageURL:(NSString *)imageURL thumbnailImageSize:(CGSize)thumbnailImageSize {
    if (imageURL) {
        NSURL *URL = [NSURL URLWithString:imageURL];
        return [[HBImageModel alloc] initWithImageURL:URL thumbnailImageSize:thumbnailImageSize];
    }else {
        return nil;
    }
}

- (instancetype)initWithImageURL:(NSURL *)imageURL thumbnailImageSize:(CGSize)thumbnailImageSize {
    if (self = [super init]) {
        _imageURL = [imageURL copy];
        _thumbnailImageSize = CGSizeEqualToSize(thumbnailImageSize, CGSizeZero) ? (CGSize){150,150} : thumbnailImageSize;
    }
    return self;
}

- (void)decodeImage {
    if (!_cachedImage) {
        if (_imageData) {
            UIImage *originalImage = [UIImage imageWithData:_imageData];
            _imageSize = originalImage.size;
            UIGraphicsBeginImageContextWithOptions(_imageSize, NO, 0);
            CGContextRef context = UIGraphicsGetCurrentContext();
            UIBezierPath *cornerPath = [UIBezierPath bezierPathWithRoundedRect:(CGRect){CGPointZero,_imageSize} cornerRadius:10];
            [cornerPath addClip];
            CGContextDrawPath(context, kCGPathFillStroke);
            [originalImage drawInRect:(CGRect){CGPointZero,_imageSize}];
            CGImageRef imageRef = CGBitmapContextCreateImage(context);
            _cachedImage = [UIImage imageWithCGImage:imageRef];
            CGImageRelease(imageRef);
            UIGraphicsEndImageContext();
        }
    }
}

- (void)createThumbnailImageIfNeeded {
    if (!_thumbnailImage && _cachedImage) {
        CGSize adjustThumbnailSize = (_imageSize.width > _thumbnailImageSize.width &&
                                      _imageSize.height > _thumbnailImageSize.height) ? _thumbnailImageSize : _imageSize;
        CGRect thumbnailImageRect = (CGRect){CGPointZero,adjustThumbnailSize};
        CGImageRef cacheImageRef = _cachedImage.CGImage;
        CGColorSpaceRef colorSpaceRef = CGColorSpaceCreateDeviceRGB();
        CGContextRef ctx = CGBitmapContextCreate(NULL, adjustThumbnailSize.width, adjustThumbnailSize.height, 8, adjustThumbnailSize.width * 4, colorSpaceRef, (CGBitmapInfo)kCGImageAlphaPremultipliedLast);
        CGColorSpaceRelease(colorSpaceRef);
        CGContextSetFillColorWithColor(ctx, [[UIColor clearColor] CGColor]);
        CGContextFillRect(ctx, thumbnailImageRect);
        CGContextDrawImage(ctx, thumbnailImageRect, cacheImageRef);
        CGImageRef newImageRef = CGBitmapContextCreateImage(ctx);
        CGContextRelease(ctx);
        _thumbnailImage = [UIImage imageWithCGImage:newImageRef];
        CGImageRelease(newImageRef);
    }
}
@end

```

2、自定义UICollectionViewCell以及列表数据源对象

```Objective-C

#pragmark - 自定义UICollectionViewCell

@interface HBImageCollectionViewCell : UICollectionViewCell

- (void)setImage:(UIImage *)image;

@end

@implementation HBImageCollectionViewCell

- (void)setImage:(UIImage *)image {
    self.contentView.layer.contents = (id)image.CGImage;
}

@end

#pragmark - 数据源对象

@interface HBCollectionViewDataSource : NSObject <UICollectionViewDataSource, UICollectionViewDelegateFlowLayout>

@property (nonatomic, copy) NSArray<NSString *> *cellIdentifiers;

+ (instancetype)dataSourceWithImageURLs:(NSArray<NSString *> *)imageURLs collectionView:(UICollectionView *)collectionView;

- (instancetype)initWithImageURLs:(NSArray<NSString *> *)imageURLs collectionView:(UICollectionView *)collectionView;

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
        _imageModels = [NSMutableArray array];
       if (imageURLs) {
           [imageURLs enumerateObjectsUsingBlock:^(NSString * _Nonnull url, NSUInteger idx, BOOL * _Nonnull stop) {
               HBImageModel *model = [HBImageModel imageModelWithImageURL:url thumbnailImageSize:flowlayout.itemSize];
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

```
