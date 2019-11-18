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
@property (nonatomic) CFRunLoopObserverRef runLoopObserver;
@property (nonatomic, strong) NSMutableOrderedSet<HBRunLoopTask *> *taskSet;

@end

@implementation HBRunLoopTaskManager

+ (instancetype)permenetThreadTaskManager {
    HBRunLoopTaskManager *taskManager = [[HBRunLoopTaskManager alloc] init];
    if (taskManager) {
        [NSThread detachNewThreadSelector:@selector(permenetThreadAction) toTarget:taskManager withObject:nil];
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
        _taskSet = [NSMutableOrderedSet orderedSet];
    }
    return self;
}

- (void)dealloc {
    if (_runLoopObserver) {
        CFRelease(_runLoopObserver);
        _runLoopObserver = NULL;
    }
}

- (BOOL)isRunLoopWaiting {
    return (_runLoop != NULL && CFRunLoopIsWaiting(_runLoop));
}

- (void)permenetThreadAction {
    NSThread *currentThread = [NSThread currentThread];
    currentThread.name = @"com.xhb.permenet.runloop.thread";
    NSMachPort *permenetMachPort = [[NSMachPort alloc] init];
    NSRunLoop *permenetRunLoop = [NSRunLoop currentRunLoop];
    _runLoop = [permenetRunLoop getCFRunLoop];
    _runLoopMode = kCFRunLoopDefaultMode;
    [permenetRunLoop addPort:permenetMachPort forMode:(__bridge NSRunLoopMode)_runLoopMode];
    [self registerRunLoopObserver];
    [permenetRunLoop run];
}

#pragma mark - 公开方法

- (void)addTask:(HBRunLoopTask *)task {
    if (task) {
        [self.taskSet addObject:task];
        NSUInteger currentTaskCount = self.taskSet.count;
        if (_maxContainerTaskCount > 0 && currentTaskCount > _maxContainerTaskCount) {
            HBRunLoopTask *firstTask = self.taskSet.firstObject;
            [firstTask invalidateInRunLoop:self.runLoop mode:self.runLoopMode];
            [self.taskSet removeObjectAtIndex:0];
        }
        if ([self isRunLoopWaiting]) {
            //触发一下RunLoop
            [task executeInRunLoop:self.runLoop mode:self.runLoopMode];
            CFRunLoopWakeUp(self.runLoop);
        }
    }
}

- (void)addTasks:(NSArray<HBRunLoopTask *> *)tasks {
    if (tasks.count > 0) {
        [self.taskSet addObjectsFromArray:tasks];
        NSUInteger newTaskCount = tasks.count;
        NSUInteger currentTaskCount = self.taskSet.count;
        CFRunLoopRef runLoop = self.runLoop;
        CFRunLoopMode runLoopMode = self.runLoopMode;
        if (_maxContainerTaskCount > 0 && currentTaskCount > _maxContainerTaskCount) {
            [self.taskSet enumerateObjectsUsingBlock:^(HBRunLoopTask * _Nonnull task, NSUInteger idx, BOOL * _Nonnull stop) {
                if (idx <= newTaskCount - 1) {
                    [task invalidateInRunLoop:runLoop mode:runLoopMode];
                    *stop = (idx == currentTaskCount - 1);
                }
            }];
            [self.taskSet removeObjectsInRange:(NSRange){0,newTaskCount}];
        }
        if ([self isRunLoopWaiting]) {
            [tasks enumerateObjectsUsingBlock:^(HBRunLoopTask * _Nonnull task, NSUInteger idx, BOOL * _Nonnull stop) {
                [task executeInRunLoop:runLoop mode:runLoopMode];
            }];
            CFRunLoopWakeUp(self.runLoop);
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

- (void)resumeTask:(HBRunLoopTask *)task {
    if (task) {
        [self.taskSet insertObject:task atIndex:0];
        [task executeInRunLoop:self.runLoop mode:self.runLoopMode];
    }
}

- (void)resumeAllTasks {
    NSMutableOrderedSet<HBRunLoopTask *> *taskSet = self.taskSet;
    if (taskSet.count > 0 && [self isRunLoopWaiting]) {
        CFRunLoopRef runLoop = self.runLoop;
        CFRunLoopMode runLoopMode = self.runLoopMode;
        [taskSet enumerateObjectsUsingBlock:^(HBRunLoopTask * _Nonnull task, NSUInteger idx, BOOL * _Nonnull stop) {
            if (!task.didFinish) {
                [task executeInRunLoop:runLoop mode:runLoopMode];
            }
        }];
    }
}

#pragma mark - 私有方法

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
