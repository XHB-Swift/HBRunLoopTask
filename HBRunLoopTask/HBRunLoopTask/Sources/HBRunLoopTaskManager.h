//
//  HBRunLoopTaskManager.h
//  HBRunLoopTask
//
//  Created by 谢鸿标 on 2019/11/13.
//  Copyright © 2019 谢鸿标. All rights reserved.
//

#import <Foundation/Foundation.h>

NS_ASSUME_NONNULL_BEGIN

@class HBRunLoopTask;

//一个在RunLoop中管理串行任务的类
@interface HBRunLoopTaskManager : NSObject

//容器队列中最大任务数
@property (nonatomic) NSUInteger maxContainerTaskCount;

//RunLoop一次可以执行的最大任务数
@property (nonatomic) NSUInteger maxExecutionTaskCount;

//常驻线程任务管理
+ (instancetype)permenetThreadTaskManager;

+ (instancetype _Nullable)taskManagerWithRunLoop:(CFRunLoopRef)runLoop
                                     runLoopMode:(CFRunLoopMode)runLoopMode;

- (instancetype _Nullable)initWithRunLoop:(CFRunLoopRef)runLoop
                              runLoopMode:(CFRunLoopMode)runLoopMode;

- (void)addTask:(HBRunLoopTask *)task;

- (void)addTasks:(NSArray<HBRunLoopTask *> *)tasks;

- (void)removeTaskWithIdentifier:(NSString *)identifier;

- (void)removeAllTasks;

- (void)resumeTask:(HBRunLoopTask *)task;

- (void)resumeAllTasks;

@end

NS_ASSUME_NONNULL_END
