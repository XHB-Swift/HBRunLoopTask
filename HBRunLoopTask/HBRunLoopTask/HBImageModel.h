//
//  HBImageModel.h
//  HBRunLoopTask
//
//  Created by 谢鸿标 on 2019/11/21.
//  Copyright © 2019 谢鸿标. All rights reserved.
//

#import <UIKit/UIKit.h>

NS_ASSUME_NONNULL_BEGIN

@interface HBImageModel : NSObject

@property (nonatomic, strong) NSIndexPath *indexPath;
@property (nonatomic, readonly) CGSize imageSize;
@property (nonatomic, readonly, copy) NSURL *imageURL;
@property (nonatomic, nullable, copy) NSData *imageData;
@property (nonatomic, nullable, copy, readonly) UIImage *cachedImage;

+ (instancetype _Nullable)imageModelWithImageURL:(NSString *)imageURL;

- (void)decodeImage;

@end

NS_ASSUME_NONNULL_END
