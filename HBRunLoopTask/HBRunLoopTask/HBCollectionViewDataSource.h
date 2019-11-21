//
//  HBCollectionViewDataSource.h
//  HBRunLoopTask
//
//  Created by 谢鸿标 on 2019/11/21.
//  Copyright © 2019 谢鸿标. All rights reserved.
//

#import <UIKit/UIKit.h>

NS_ASSUME_NONNULL_BEGIN

@interface HBImageCollectionViewCell : UICollectionViewCell

@property (nonatomic, nullable, strong) UIImage *image;

@end


@interface HBCollectionViewDataSource : NSObject <UICollectionViewDataSource, UICollectionViewDelegateFlowLayout>

@property (nonatomic, weak) UICollectionView *collectionView;

@property (nonatomic, copy) NSArray<NSString *> *cellIdentifiers;

+ (instancetype)dataSourceWithImageURLs:(NSArray<NSString *> *)imageURLs;

- (instancetype)initWithImageURLs:(NSArray<NSString *> *)imageURLs;

@end

NS_ASSUME_NONNULL_END
