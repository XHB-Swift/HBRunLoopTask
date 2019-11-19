//
//  HBRunLoopTaskManager.m
//  HBRunLoopTask
//
//  Created by 谢鸿标 on 2019/11/13.
//  Copyright © 2019 谢鸿标. All rights reserved.
//

#import "HBRunLoopTaskManager.h"
#import "HBRunLoopTask.h"

@interface HBRunLoopTaskManager ()

@property (nonatomic) CFRunLoopRef runLoop;
@property (nonatomic) CFRunLoopMode runLoopMode;
@property (nonatomic) CFRunLoopSourceRef holdingRunLoop;
@property (nonatomic) CFRunLoopObserverRef runLoopObserver;
@property (nonatomic, strong) NSMutableOrderedSet<HBRunLoopTask *> *taskSet;

@end

@implementation HBRunLoopTaskManager

+ (instancetype)permanentThreadTaskManager {
    HBRunLoopTaskManager *taskManager = [[HBRunLoopTaskManager alloc] init];
    if (taskManager) {
        [NSThread detachNewThreadSelector:@selector(permanentThreadAction) toTarget:taskManager withObject:nil];
    }
    return taskManager;
}

+ (instancetype)controllableThreadTaskManager {
    HBRunLoopTaskManager *taskManager = [[HBRunLoopTaskManager alloc] init];
    if (taskManager) {
        [NSThread detachNewThreadSelector:@selector(controllableThreadAction) toTarget:taskManager withObject:nil];
    }
    return taskManager;
}

+ (instancetype _Nullable)taskManagerWithRunLoop:(CFRunLoopRef)runLoop
                                     runLoopMode:(CFRunLoopMode)runLoopMode {
    return [[self alloc] initWithRunLoop:runLoop runLoopMode:runLoopMode];
}

- (instancetype _Nullable)initWithRunLoop:(CFRunLoopRef)runLoop runLoopMode:(CFRunLoopMode)runLoopMode {
    if (runLoop != NULL && runLoopMode != NULL) {
        if (self = [self init]) {
            _runLoop = runLoop;
            _runLoopMode = runLoopMode;
            [self registerRunLoopObserver];
        }
        return self;
    }
    return nil;
}

- (instancetype)init {
    if (self = [super init]) {
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

- (void)addTask:(HBRunLoopTask *)task {
    if (task) {
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

//检测RunLoop是否在等待输入源
- (BOOL)isRunLoopWaiting {
    return (_runLoop != NULL && CFRunLoopIsWaiting(_runLoop));
}

//常驻线程启动RunLoop，App内无法退出该RunLoop
- (void)permanentThreadAction {
    NSThread *currentThread = [NSThread currentThread];
    currentThread.name = @"com.xhb.permenet.runloop.thread";
    NSMachPort *permanentMachPort = [[NSMachPort alloc] init];
    NSRunLoop *currentRunLoop = [NSRunLoop currentRunLoop];
    _runLoop = [currentRunLoop getCFRunLoop];
    _runLoopMode = kCFRunLoopDefaultMode;
    [currentRunLoop addPort:permanentMachPort forMode:(__bridge NSRunLoopMode)_runLoopMode];
    [self registerRunLoopObserver];
    [currentRunLoop run];
}

//可控线程使用CFRunLoopSourceRef启动RunLoop
- (void)controllableThreadAction {
    NSThread *currentThread = [NSThread currentThread];
    currentThread.name = @"com.xhb.permenet.runloop.thread";
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

//退出可控线程的RunLoop
- (void)exitControllableThread {
    BOOL canExitRunLoop = _holdingRunLoop && CFRunLoopSourceIsValid(_holdingRunLoop) &&
                          _runLoop && CFRunLoopContainsSource(_runLoop, _holdingRunLoop, _runLoopMode);
    if (canExitRunLoop) {
        CFRunLoopRemoveSource(_runLoop, _holdingRunLoop, _runLoopMode);
        [self wakeupRunLoop];
    }
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
    HBRunLoopTaskManager *manager = (__bridge HBRunLoopTaskManager *)info;
    [manager runLoopExecutesTasks];
}

@end
