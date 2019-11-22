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
//            CGImageRef imageRef = originalImage.CGImage;
//            size_t width = CGImageGetWidth(imageRef);
//            size_t height = CGImageGetHeight(imageRef);
//            CGColorSpaceRef colorSpace = CGImageGetColorSpace(imageRef);
//            size_t bitsPerComponent = CGImageGetBitsPerComponent(imageRef);
//            size_t bitsPerPixel = CGImageGetBitsPerPixel(imageRef);
//            size_t bytesPerRow = CGImageGetBytesPerRow(imageRef);
//            CGBitmapInfo bitmapInfo = CGImageGetBitmapInfo(imageRef);
//            CGDataProviderRef dataProvider = CGImageGetDataProvider(imageRef);
//            CFDataRef data = CGDataProviderCopyData(dataProvider);
//            CGDataProviderRef newDataProvider = CGDataProviderCreateWithCFData(data);
//            CFRelease(data);
//            CGImageRef newImageRef = CGImageCreate(width, height, bitsPerComponent, bitsPerPixel, bytesPerRow, colorSpace, bitmapInfo, newDataProvider, NULL, false, kCGRenderingIntentDefault);
//            CFRelease(newDataProvider);
//            _cachedImage = [[UIImage alloc] initWithCGImage:newImageRef];
//            CGImageRelease(newImageRef);
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
