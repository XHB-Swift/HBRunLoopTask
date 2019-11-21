//
//  HBRunLoopTask.m
//  HBRunLoopTask
//
//  Created by 谢鸿标 on 2019/11/13.
//  Copyright © 2019 谢鸿标. All rights reserved.
//

#import "HBRunLoopTask.h"

@interface HBRunLoopTask ()

@property (nonatomic) CFRunLoopSourceRef runLoopSource;
@property (nonatomic, weak) id target;
@property (nonatomic) SEL action;
@property (nonatomic, strong) id object;

@end

@implementation HBRunLoopTask

+ (instancetype)runLoopTaskWithTarget:(id)target action:(SEL)action {
    return [[self alloc] initWithTarget:target action:action];
}

- (instancetype)initWithTarget:(id)target action:(SEL)action {
    return [self initWithTarget:target action:action object:nil];
}

+ (instancetype)runLoopTaskWithTarget:(id)target action:(SEL)action object:(id _Nullable)object {
    return [[self alloc] initWithTarget:target action:action object:object];
}

- (instancetype)initWithTarget:(id)target action:(SEL)action object:(id _Nullable)object {
    if (self = [self init]) {
        _target = target;
        _action = action;
        _object = object;
    }
    return self;
}

+ (instancetype)runLoopTaskWithIdentifier:(NSString *)identifier target:(id)target action:(SEL)action {
    return [[self alloc] initWithIdentifier:identifier target:target action:action];
}

- (instancetype)initWithIdentifier:(NSString *)identifier target:(id)target action:(SEL)action {
    if (self = [self initWithTarget:target action:action]) {
        _identifier = [identifier copy];
    }
    return self;
}

+ (instancetype)runLoopTaskWithIdentifier:(NSString *)identifier target:(id)target action:(SEL)action object:(id)object {
    return [[self alloc] initWithIdentifier:identifier target:target action:action object:object];
}

- (instancetype)initWithIdentifier:(NSString *)identifier target:(id)target action:(SEL)action object:(id)object {
    if (self = [self initWithTarget:target action:action object:object]) {
        _identifier = [identifier copy];
    }
    return self;
}

- (instancetype)init {
    if (self = [super init]) {
        CFRunLoopSourceContext runLoopSourceCtx = {
            .version = 0,
            .info = (__bridge void *)self,
            .retain = NULL,
            .release = NULL,
            .copyDescription = NULL,
            .hash = NULL,
            .schedule = NULL,
            .cancel = NULL,
            .perform = &HBRunLoopTaskPerformSource,
        };
        _finished = NO;
        _runLoopSource = CFRunLoopSourceCreate(NULL, 0, &runLoopSourceCtx);
    }
    return self;
}

//判断两个Task是否相等的关键点：对象地址，task标识，CFRunLoopSourceRef
- (BOOL)isEqual:(id)object {
    BOOL equal = (self == object);
    if (!equal) {
        if ([object isKindOfClass:[HBRunLoopTask class]]) {
            equal = [self isEqualToTask:object];
        }
    }
    return equal;
}

- (BOOL)isEqualToTask:(HBRunLoopTask *)task {
    BOOL equal = NO;
    if (task) {
        equal = (_runLoopSource == task.runLoopSource);
        if (!equal && task.identifier) {
            equal = [_identifier isEqualToString:task.identifier];
        }
    }
    return equal;
}

//重写哈希值
- (NSUInteger)hash {
    id runLoopSource = (__bridge id)_runLoopSource;
    NSUInteger h = [runLoopSource hash];
    if (_identifier) {
        NSUInteger identifierHash = [_identifier hash];
        //不能写成 h ^ identifierHash，当标识符不为空要以标识符为优先级区分Task
        h = identifierHash ^ h;
    }
    return h;
}

- (void)dealloc {
    if (_runLoopSource) {
        CFRelease(_runLoopSource);
        _runLoopSource = NULL;
    }
//    NSLog(@"%s _runLoopSource = %d", __func__, (_runLoopSource == NULL));
}

- (void)executeInRunLoop:(CFRunLoopRef)runLoop mode:(CFRunLoopMode)runLoopMode {
    if (!self.didFinish && runLoop != NULL) {
        CFRunLoopSourceRef taskSource = self.runLoopSource;
        if (taskSource != NULL && CFRunLoopSourceIsValid(taskSource)) {
            CFRunLoopSourceSignal(taskSource);
            CFRunLoopAddSource(runLoop, taskSource, runLoopMode);
        }
    }
}

- (void)invalidateInRunLoop:(CFRunLoopRef)runLoop mode:(CFRunLoopMode)runLoopMode {
    CFRunLoopSourceRef taskSource = self.runLoopSource;
    if (taskSource != NULL && CFRunLoopSourceIsValid(taskSource) && runLoop != NULL) {
        CFRunLoopSourceInvalidate(taskSource);
        if (CFRunLoopContainsSource(runLoop, taskSource, runLoopMode)) {
            CFRunLoopRemoveSource(runLoop, taskSource, runLoopMode);
        }
    }
//    NSLog(@"thread = %@", [NSThread currentThread]);
}

- (void)executeTask {
    id target = self.target;
    SEL action = self.action;
    if (target && [target respondsToSelector:action]) {
        IMP imp = [target methodForSelector:action];
        if (imp != NULL) {
            void(*func)(id,SEL,id) = (void *)imp;
            func(target,action,self.object);
        }
    }
    _finished = YES;
}

static inline void HBRunLoopTaskPerformSource(void *info) {
    HBRunLoopTask *task = (__bridge HBRunLoopTask *)info;
    [task executeTask];
}

@end
