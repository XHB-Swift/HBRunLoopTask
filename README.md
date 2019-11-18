# HBRunLoopTask
基于CFRunLoopRef，CFRunLoopSourceRef，CFRunLoopObserverRef封装的一个任务调度管理类。所有任务放到线程的RunLoop中可以根据设置，决定RunLoop一次可以执行几个任务
## Usage
``` Objective-C
#import "HBRunLoopTask.h"
#import "HBRunLoopTaskManager.h"

//创建一个使用自带常驻线程的RunLoop管理器
HBRunLoopTaskManager *taskManager = [HBRunLoopTaskManager permenetThreadTaskManager];
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

```

2、列表数据源对象

```Objective-C

@interface HBTableViewDataSource : NSObject <UITableViewDataSource>

@property (nonatomic, copy) NSArray<NSString *> *cellIdentifiers;

@property (nonatomic, weak) UITableView *tableView;

+ (instancetype)dataSourceWithImageURLs:(NSArray<NSString *> *)imageURLs;

- (instancetype)initWithImageURLs:(NSArray<NSString *> *)imageURLs;

@end

@interface HBTableViewDataSource ()

@property (nonatomic, strong) NSMutableArray<HBTableViewCellImageModel *> *imageModels;
@property (nonatomic, strong) HBRunLoopTaskManager *taskManager;
@property (nonatomic, getter=shouldUpdate) BOOL update;

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
        _taskManager = [HBRunLoopTaskManager permenetThreadTaskManager];
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
        if (model.imageData) {
            if (!model.cachedImage) {
                HBRunLoopTask *task = [HBRunLoopTask runLoopTaskWithTarget:self action:@selector(runLoopTaskWithObject:) object:model];
                [self.taskManager addTask:task];
            }else {
                cell.imageView.image = model.cachedImage;
            }
        }
    }
    return cell;
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

#pragma mark - RunLoop负责下载以及解压图片任务

- (void)runLoopTaskWithObject:(HBTableViewCellImageModel *)object {
    object.imageData = [NSData dataWithContentsOfURL:object.imageURL];
    [object decodeImage];
    dispatch_async(dispatch_get_main_queue(), ^{
        [self.tableView reloadRowsAtIndexPaths:@[object.indexPath] withRowAnimation:(UITableViewRowAnimationAutomatic)];
    });
}
@end

```
