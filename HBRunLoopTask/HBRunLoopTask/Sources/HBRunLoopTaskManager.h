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

//是否在添加任务之后立即执行，默认YES
@property (nonatomic) BOOL shouldExecuteTaskImmediately;

//常驻线程任务管理
+ (instancetype)permanentThreadTaskManager;

//可控制线程声明周期的任务管理
+ (instancetype)controllableThreadTaskManager;

//退出可控线程的RunLoop
- (void)exitControllableThread;

+ (instancetype _Nullable)taskManagerWithRunLoop:(CFRunLoopRef)runLoop
                                     runLoopMode:(CFRunLoopMode)runLoopMode;

- (instancetype _Nullable)initWithRunLoop:(CFRunLoopRef)runLoop
                              runLoopMode:(CFRunLoopMode)runLoopMode;

- (void)addTask:(HBRunLoopTask *)task;

- (void)addTasks:(NSArray<HBRunLoopTask *> *)tasks;

- (void)removeTaskWithIdentifier:(NSString *)identifier;

- (void)removeAllTasks;

- (void)wakeupRunLoop;

@end

NS_ASSUME_NONNULL_END
