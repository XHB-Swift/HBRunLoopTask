//
//  HBRunLoopTaskThread.m
//  HBRunLoopTask
//
//  Created by 谢鸿标 on 2019/11/22.
//  Copyright © 2019 谢鸿标. All rights reserved.
//

#import "HBRunLoopTaskThread.h"
#import "HBRunLoopTask.h"

@interface HBRunLoopTaskThread ()

@property (nonatomic) CFRunLoopRef runLoop;
@property (nonatomic) CFRunLoopMode runLoopMode;
@property (nonatomic) CFRunLoopSourceRef holdingRunLoop;
@property (nonatomic) CFRunLoopObserverRef runLoopObserver;
@property (nonatomic, strong) NSMutableOrderedSet<HBRunLoopTask *> *taskSet;

@end

@implementation HBRunLoopTaskThread

+ (instancetype)runLoopTaskThread {
    HBRunLoopTaskThread *thread = [[HBRunLoopTaskThread alloc] init];
    [thread start];
    return thread;
}

- (instancetype)init {
    if (self = [super init]) {
        self.name = @"com.xhb.runloop.task.thread";
        _maxContainerTaskCount = 5;
        _maxExecutionTaskCount = 1;
        _runLoop = NULL;
        _runLoopMode = NULL;
        _runLoopObserver = NULL;
        _shouldExecuteTaskImmediately = YES;
        _taskSet = [NSMutableOrderedSet orderedSet];
    }
    return self;
}

- (void)dealloc {
    if (_runLoopObserver) {
        CFRelease(_runLoopObserver);
        _runLoopObserver = NULL;
    }
    if (_holdingRunLoop) {
        CFRelease(_holdingRunLoop);
        _holdingRunLoop = NULL;
    }
}

#pragma mark - 公开方法

- (NSUInteger)currentTaskCount {
    return _taskSet.count;
}

- (BOOL)containsTask:(HBRunLoopTask *)task {
    BOOL flag = NO;
    if (task) {
        flag = [self.taskSet containsObject:task];
    }
    return flag;
}

- (BOOL)containsTaskWithIdentifier:(NSString *)identifier {
    __block BOOL flag = NO;
    if (identifier) {
        [self.taskSet enumerateObjectsUsingBlock:^(HBRunLoopTask * _Nonnull task, NSUInteger idx, BOOL * _Nonnull stop) {
            *stop = flag = [task.identifier isEqualToString:identifier];
        }];
    }
    return flag;
}

- (void)addTask:(HBRunLoopTask *)task {
    if (task) {
        if (![self containsTask:task]) {
            NSUInteger currentTaskCount = self.taskSet.count + 1;
            if (_maxContainerTaskCount > 0 && currentTaskCount > _maxContainerTaskCount) {
                HBRunLoopTask *overflowTask = self.taskSet.firstObject;
                if (overflowTask) {
                    [overflowTask invalidateInRunLoop:self.runLoop mode:self.runLoopMode];
                    [self.taskSet removeObject:overflowTask];
                }
            }
            [self.taskSet addObject:task];
            if (self.shouldExecuteTaskImmediately) {
                [self wakeupRunLoop];
            }
        }
    }
}

- (void)addTasks:(NSArray<HBRunLoopTask *> *)tasks {
    NSUInteger newTaskCount = tasks.count;
    if (newTaskCount > 0) {
        [self.taskSet addObjectsFromArray:tasks];
        NSUInteger currentTaskCount = self.taskSet.count;
        CFRunLoopRef runLoop = self.runLoop;
        CFRunLoopMode runLoopMode = self.runLoopMode;
        if (_maxContainerTaskCount > 0 && currentTaskCount > _maxContainerTaskCount) {
            NSUInteger overflowLength = currentTaskCount - _maxContainerTaskCount;
            NSIndexSet *overflowIndexSet = [NSIndexSet indexSetWithIndexesInRange:(NSRange){0,overflowLength}];
            NSArray<HBRunLoopTask *> *overflowTasks = [self.taskSet objectsAtIndexes:overflowIndexSet];
            [overflowTasks enumerateObjectsUsingBlock:^(HBRunLoopTask * _Nonnull overflowTask, NSUInteger idx, BOOL * _Nonnull stop) {
                [overflowTask invalidateInRunLoop:runLoop mode:runLoopMode];
            }];
            [self.taskSet removeObjectsInArray:overflowTasks];
        }
        if (self.shouldExecuteTaskImmediately) {
            [self wakeupRunLoop];
        }
    }
}

- (void)removeTaskWithIdentifier:(NSString *)identifier {
    NSMutableArray<HBRunLoopTask *> *removedTasks = [NSMutableArray array];
    [self.taskSet enumerateObjectsUsingBlock:^(HBRunLoopTask * _Nonnull task, NSUInteger idx, BOOL * _Nonnull stop) {
        if ([identifier isEqualToString:task.identifier]) {
            [removedTasks addObject:task];
            [task invalidateInRunLoop:self.runLoop mode:self.runLoopMode];
        }
    }];
    if (removedTasks.count > 0) {
        [self.taskSet removeObjectsInArray:removedTasks];
    }
}

- (void)removeAllTasks {
    NSMutableArray<HBRunLoopTask *> *removedTasks = [NSMutableArray array];
    [self.taskSet enumerateObjectsUsingBlock:^(HBRunLoopTask * _Nonnull task, NSUInteger idx, BOOL * _Nonnull stop) {
        [removedTasks addObject:task];
        [task invalidateInRunLoop:self.runLoop mode:self.runLoopMode];
    }];
    if (removedTasks.count > 0) {
        [self.taskSet removeObjectsInArray:removedTasks];
    }
}

//唤醒等待中的RunLoop
- (void)wakeupRunLoop {
    if ([self isRunLoopWaiting]) { //RunLoop正在等待
        //唤醒RunLoop
        CFRunLoopWakeUp(self.runLoop);
    }
}

#pragma mark - 私有方法

- (void)main {
    NSRunLoop *currentRunLoop = [NSRunLoop currentRunLoop];
    _runLoop = [currentRunLoop getCFRunLoop];
    _runLoopMode = kCFRunLoopDefaultMode;
    [self registerRunLoopObserver];
    //创建一个维持RunLoop的Source
    CFRunLoopSourceContext runLoopSourceCtx = {
        .version = 0,
        .info = (__bridge void *)self,
        .retain = NULL,
        .release = NULL,
        .copyDescription = NULL,
        .hash = NULL,
        .schedule = NULL,
        .cancel = NULL,
        .perform = NULL,
    };
    _holdingRunLoop = CFRunLoopSourceCreate(NULL, 0, &runLoopSourceCtx);
    if (_holdingRunLoop != NULL) {
        CFRunLoopAddSource(_runLoop, _holdingRunLoop, _runLoopMode);
        while ([currentRunLoop runMode:(__bridge NSRunLoopMode)_runLoopMode beforeDate:[NSDate distantFuture]]) {
        }
    }
}

- (void)exitRunLoopThread {
    BOOL canExitRunLoop = _holdingRunLoop && CFRunLoopSourceIsValid(_holdingRunLoop) &&
                          _runLoop && CFRunLoopContainsSource(_runLoop, _holdingRunLoop, _runLoopMode);
    if (canExitRunLoop) {
        [self removeAllTasks];
        CFRunLoopRemoveSource(_runLoop, _holdingRunLoop, _runLoopMode);
        [self wakeupRunLoop];
    }
}

//检测RunLoop是否在等待输入源
- (BOOL)isRunLoopWaiting {
    return (_runLoop != NULL && CFRunLoopIsWaiting(_runLoop));
}

- (void)registerRunLoopObserver {
    CFRunLoopObserverContext runLoopObserverCtx = {
        .version = 0,
        .info = (__bridge void *)self,
        .retain = NULL,
        .release = NULL,
        .copyDescription = NULL
    };
    _runLoopObserver = CFRunLoopObserverCreate(NULL, kCFRunLoopBeforeWaiting, YES, 0, HBRunLoopTaskManagerObserve, &runLoopObserverCtx);
    CFRunLoopAddObserver(self.runLoop, self.runLoopObserver, self.runLoopMode);
}

- (void)removeFinishedTasks {
    NSMutableOrderedSet<HBRunLoopTask *> *taskSet = self.taskSet;
    if (taskSet.count > 0) {
        NSMutableArray<HBRunLoopTask *> *removedTasks = [NSMutableArray array];
        CFRunLoopRef runLoop = self.runLoop;
        CFRunLoopMode runLoopMode = self.runLoopMode;
        [taskSet enumerateObjectsUsingBlock:^(HBRunLoopTask * _Nonnull task, NSUInteger idx, BOOL * _Nonnull stop) {
            if (task.didFinish) {
                [task invalidateInRunLoop:runLoop mode:runLoopMode];
                [removedTasks addObject:task];
            }
        }];
        [taskSet removeObjectsInArray:removedTasks];
    }
}

- (void)runLoopExecutesTasks {
    NSMutableOrderedSet<HBRunLoopTask *> *taskSet = self.taskSet;
    //清空已完成的任务
    [self removeFinishedTasks];
    if (taskSet.count == 0) { return; }
    CFRunLoopRef runLoop = self.runLoop;
    CFRunLoopMode runLoopMode = self.runLoopMode;
    //一次RunLoop等待，以出队列的形式执行任务
//    NSLog(@"taskSet = %@", taskSet);
    if (self.maxExecutionTaskCount > 1) {
        [taskSet enumerateObjectsUsingBlock:^(HBRunLoopTask * _Nonnull task, NSUInteger idx, BOOL * _Nonnull stop) {
            
            *stop = (idx == self.maxExecutionTaskCount - 1);
            [task executeInRunLoop:runLoop mode:runLoopMode];
        }];
        //必要时启动RunLoop
        CFRunLoopWakeUp(runLoop);
    }else {
        HBRunLoopTask *task = taskSet.firstObject;
        if (task) {
            [task executeInRunLoop:runLoop mode:runLoopMode];
            //必要时启动RunLoop
            CFRunLoopWakeUp(runLoop);
        }
    }
}

static inline void HBRunLoopTaskManagerObserve(CFRunLoopObserverRef observer, CFRunLoopActivity activity, void *info) {
    if (activity != kCFRunLoopBeforeWaiting) { return; }
    HBRunLoopTaskThread *thread = (__bridge HBRunLoopTaskThread *)info;
    [thread runLoopExecutesTasks];
}


@end
