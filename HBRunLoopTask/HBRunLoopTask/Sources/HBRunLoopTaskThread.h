//
//  HBRunLoopTaskThread.h
//  HBRunLoopTask
//
//  Created by 谢鸿标 on 2019/11/22.
//  Copyright © 2019 谢鸿标. All rights reserved.
//

#import <Foundation/Foundation.h>

NS_ASSUME_NONNULL_BEGIN

@class HBRunLoopTask;

@interface HBRunLoopTaskThread : NSThread

//容器队列中最大任务数，默认5
@property (nonatomic) NSUInteger maxContainerTaskCount;

//RunLoop一次可以执行的最大任务数，默认1
@property (nonatomic) NSUInteger maxExecutionTaskCount;

//当任务数量
@property (nonatomic, readonly) NSUInteger currentTaskCount;

//是否在添加任务之后立即执行，默认YES
@property (nonatomic) BOOL shouldExecuteTaskImmediately;

+ (instancetype)runLoopTaskThread;

- (void)addTask:(HBRunLoopTask *)task;

- (void)addTasks:(NSArray<HBRunLoopTask *> *)tasks;

- (void)removeTaskWithIdentifier:(NSString *)identifier;

- (void)removeAllTasks;

//唤醒线程RunLoop
- (void)wakeupRunLoop;

- (BOOL)containsTask:(HBRunLoopTask *)task;

- (BOOL)containsTaskWithIdentifier:(NSString *)identifier;

//退出RunLoop
- (void)exitRunLoopThread;

@end

NS_ASSUME_NONNULL_END
