//
//  HBRunLoopTask.h
//  HBRunLoopTask
//
//  Created by 谢鸿标 on 2019/11/13.
//  Copyright © 2019 谢鸿标. All rights reserved.
//

#import <Foundation/Foundation.h>

NS_ASSUME_NONNULL_BEGIN

@interface HBRunLoopTask : NSObject

@property (nonatomic, readonly, getter=didFinish) BOOL finished;

@property (nonatomic, nullable, copy) NSString *identifier;

+ (instancetype)runLoopTaskWithTarget:(id)target action:(SEL)action;

- (instancetype)initWithTarget:(id)target action:(SEL)action;

+ (instancetype)runLoopTaskWithTarget:(id)target action:(SEL)action object:(id _Nullable)object;

- (instancetype)initWithTarget:(id)target action:(SEL)action object:(id _Nullable)object;

+ (instancetype)runLoopTaskWithIdentifier:(NSString * _Nullable)identifier target:(id)target action:(SEL)action;

- (instancetype)initWithIdentifier:(NSString * _Nullable)identifier target:(id)target action:(SEL)action;

+ (instancetype)runLoopTaskWithIdentifier:(NSString * _Nullable)identifier target:(id)target action:(SEL)action object:(id _Nullable)object;

- (instancetype)initWithIdentifier:(NSString * _Nullable)identifier target:(id)target action:(SEL)action object:(id _Nullable)object;

- (void)executeInRunLoop:(CFRunLoopRef)runLoop mode:(CFRunLoopMode)runLoopMode;

- (void)invalidateInRunLoop:(CFRunLoopRef)runLoop mode:(CFRunLoopMode)runLoopMode;

@end

NS_ASSUME_NONNULL_END
