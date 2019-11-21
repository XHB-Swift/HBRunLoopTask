//
//  HBImageModel.m
//  HBRunLoopTask
//
//  Created by 谢鸿标 on 2019/11/21.
//  Copyright © 2019 谢鸿标. All rights reserved.
//

#import "HBImageModel.h"

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
    if (self = [super init]) {
        _imageURL = [imageURL copy];
    }
    return self;
}

- (void)decodeImage {
    if (!_cachedImage) {
        if (_imageData) {
            UIImage *originalImage = [UIImage imageWithData:_imageData];
            _imageSize = originalImage.size;
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
