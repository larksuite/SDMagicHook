//
//  SDMagicHook.m
//  SDMagicHookDemo
//
//  Created by  on 2019/11/20.
//  Copyright © 2019 gaoshaodong. All rights reserved.
//

#import "SDMagicHook.h"
#import <objc/runtime.h>
#import <objc/message.h>
#import <pthread.h>
#import <os/lock.h>
#import "SDNewClassManager.h"
#import "SDClassManagerLock.h"
#import "SDDict.h"
#import "SDOrderedDict.h"

BOOL SDMagicHookDebugFlag = true;


NSString* createSelHeaderString(NSString *str, int index) {
    return [NSString stringWithFormat:@"__%d_%@", index, str];
}

SEL createSel(SEL sel, NSString *str) {
    NSString *originalSelStr = NSStringFromSelector(sel);
    NSString *newSelStr = [NSString stringWithFormat:@"%@_SD_%@", str, originalSelStr];
    return NSSelectorFromString(newSelStr);
}

SEL createSelA(SEL sel, int index) {
    return createSel(sel, createSelHeaderString(@"A", index));
}

SEL createSelB(SEL sel, int index) {
    return createSel(sel, createSelHeaderString(@"B", index));
}

NSString* currentThreadTag() {
    mach_port_t machTID = pthread_mach_thread_np(pthread_self());
    return [NSString stringWithFormat:@"%d", machTID];
}

NSMutableDictionary *threadStoredDictForEntry(NSString *entry) {
    NSMutableDictionary *res = [[NSThread currentThread].threadDictionary valueForKey:entry];
    if (!res) {
        res = [NSMutableDictionary new];
        [[NSThread currentThread].threadDictionary setValue:res forKey:entry];
    }
    return res;
}

NSString *entryForThreadStoredDict(const NSString *const key, NSString *className) {
    return [NSString stringWithFormat:@"%@-%@", key, className];
}

NSMutableDictionary *threadStoredDict(const NSString *const key, NSString *className) {
    return threadStoredDictForEntry(entryForThreadStoredDict(key, className));
}

static NSString *const currentCallIndexDictKey = @"SDMagicHook-currentCallIndexDictKey";
static NSString *const originalCallFlagDictKey = @"SDMagicHook-originalCallFlagDictKey";
static NSString *const debugOriginalCallDictKey = @"SDMagicHook-debugOriginalCallDictKey";
static NSString *const keyForOriginalCallFlag = @"SDMagicHook-keyForOriginalCallFlag";

@implementation NSObject (SDMagicHook)

- (SDNewClassManager *)getClassManager {
    SDNewClassManager *mgr = objc_getAssociatedObject(self, _cmd);
    if (!mgr) {
        @synchronized (self) {
            if (!objc_getAssociatedObject(self, _cmd)) {
                mgr = [SDNewClassManager new];
                objc_setAssociatedObject(self, _cmd, mgr, OBJC_ASSOCIATION_RETAIN_NONATOMIC);
            }
        }
    }
    return mgr;
}

- (SDClassManagerLock *)getManagerLock {
    SDClassManagerLock *mgrLock = objc_getAssociatedObject(self, _cmd);
    if (!mgrLock) {
        @synchronized (self) {
            if (!objc_getAssociatedObject(self, _cmd)) {
                mgrLock = [SDClassManagerLock new];
                objc_setAssociatedObject(self, _cmd, mgrLock, OBJC_ASSOCIATION_RETAIN_NONATOMIC);
            }
        }
    }
    return mgrLock;
}

- (NSMutableDictionary *)threadStoredDictFor:(NSString *)key {
    NSString *entry = entryForThreadStoredDict(key, [NSString stringWithCString:class_getName(object_getClass(self)) encoding:NSUTF8StringEncoding]);
    return threadStoredDictForEntry(entry);
}

- (void)setOriginalCallFlag:(BOOL)flag {
    NSMutableDictionary *dict = threadStoredDict(originalCallFlagDictKey, [self getClassManager].className);
    [dict setValue:@(flag) forKey:keyForOriginalCallFlag];
}

- (BOOL)shouldCallOriginalMethod {
    NSMutableDictionary *dict = threadStoredDict(originalCallFlagDictKey, [self getClassManager].className);
    BOOL res = NO;
    if (dict) {
        res = [dict[keyForOriginalCallFlag] boolValue];
    }
    return res;
}

- (void)callOriginalMethodInBlock:(CallOriginalMethodBlock)blk {
    [self setOriginalCallFlag: true];
    blk();
}

- (int)getCurrentCallIndex:(SEL)sel {
    NSDictionary *dict = threadStoredDict(currentCallIndexDictKey, [self getClassManager].className);//objc_getAssociatedObject(self, @selector(setCurrentCallIndex:forSel:));
    int res = 0;
    if (dict) {
        res = [[dict valueForKey:NSStringFromSelector(sel)] intValue];
    }
    return res;
}

- (void)setCurrentCallIndex:(int)index forSel:(SEL)sel {
    NSMutableDictionary *dict = threadStoredDict(currentCallIndexDictKey, [self getClassManager].className);
    [dict setValue:@(MAX(0, index)) forKey:NSStringFromSelector(sel)];
}

/// ensure threadsafe on call by yourself
- (void)set_sd_resetCount:(int)count forSel:(SEL)sel {
    [[self getClassManager].resetCountDict setValue:@(count) forKey:NSStringFromSelector(sel)];
}

- (int)sd_resetCountForSel:(SEL)sel {
    NSDictionary *dict = [self getClassManager].resetCountDict;
    return [dict[NSStringFromSelector(sel)] intValue];
}

- (NSString *)hookMethod:(SEL)sel impBlock:(id)block {
    return [self hookMethod:sel file:NULL line:0 impBlock:block];
}

- (void)hookMethod:(SEL)sel key:(const void *)key impBlock:(id)block {
    NSString *strId = nil;
    if (key) {
        strId = [NSString stringWithFormat:@"%p", key];
    }
    [self hookMethod:sel strId:strId impBlock:block];
}

- (NSString *)hookMethod:(SEL)sel file:(char *)file line:(int)line impBlock:(id)block {
    NSString *strId = nil;
    if (line) {
        strId = [NSString stringWithFormat:@"%s_%d", file, line];
    }
    return [self hookMethod:sel strId:strId imp:imp_implementationWithBlock(block)];
}

- (void)hookMethod:(SEL)sel strId:(NSString *)strId impBlock:(id)block {
    [self hookMethod:sel strId:strId imp:imp_implementationWithBlock(block)];
}

- (NSString *)hookMethod:(SEL)sel strId:(NSString *)strId imp:(IMP)imp {
    pthread_rwlock_wrlock(&[self getManagerLock]->_rw_lock3);
    SDNewClassManager *mgr = [self getClassManager];
    NSString *selStr = NSStringFromSelector(sel);
    Class originalCls = self.class;
    Class currentCls = object_getClass(self);
    if (strId) {
        NSString *targetSelString = [mgr.sel_block_dict valueForMainKey:selStr subKey:strId];
        if (targetSelString) {
            Method m = class_getInstanceMethod(currentCls, NSSelectorFromString(targetSelString));
            method_setImplementation(m, imp);
            return strId;
        }
    }
    const char *originalClsName = class_getName(originalCls);
    NSString *newName = [NSString stringWithFormat:@"SDMagicHook_%s_%p_%d", originalClsName, self, mgr.randomFlag];
    int resetTimes = [self sd_resetCountForSel:sel];
    Method method = class_getInstanceMethod(currentCls, sel);
    Class cls = NSClassFromString(newName);;
    if (cls == nil) {
        cls = objc_allocateClassPair(currentCls, newName.UTF8String, 0);
        SEL forwardSel = @selector(forwardInvocation:);
        Method sdForwardMethod = class_getInstanceMethod([NSObject class], @selector(sd_forwardInvocation:));
        class_addMethod(cls, forwardSel, method_getImplementation(sdForwardMethod), method_getTypeEncoding(sdForwardMethod));
        [self addGetClassImpToClass:cls];
        objc_registerClassPair(cls);
        SDNewClassManager *mgr = [self getClassManager];
        mgr.className = newName;
        [mgr.classArr addObject:cls];
        mgr.onClassDispose = ^{
            NSThread *main = [NSThread mainThread];
            NSArray *keys = @[currentCallIndexDictKey, originalCallFlagDictKey, debugOriginalCallDictKey, keyForOriginalCallFlag];
            NSMutableDictionary *dict = main.threadDictionary;
            [keys enumerateObjectsUsingBlock:^(NSString * _Nonnull key, NSUInteger idx, BOOL * _Nonnull stop) {
                if ([dict valueForKey:entryForThreadStoredDict(key, newName)] == nil) {
                    *stop = YES;
                    return;
                }
                [dict removeObjectForKey:entryForThreadStoredDict(key, newName)];
            }];
        };
    }
    if (cls == nil) {
        return nil;
    }

    NSAssert(method != NULL, ([NSString stringWithFormat:@"The Selector `%@` may be wrong, please check it!", selStr]));
    IMP originalImp = method_getImplementation(method);
    const char *types = method_getTypeEncoding(method);
    IMP msgForwardImp = _objc_msgForward;
    #if !defined(__arm64__)
    if (types[0] == '{') {
        //In some cases that returns struct, we should use the '_stret' API:
        //http://sealiesoftware.com/blog/archive/2008/10/30/objc_explain_objc_msgSend_stret.html
        //NSMethodSignature knows the detail but has no API to return, we can only get the info from debugDescription.
        NSMethodSignature *methodSignature = [NSMethodSignature signatureWithObjCTypes:types];
        if ([methodSignature.debugDescription rangeOfString:@"is special struct return? YES"].location != NSNotFound) {
            msgForwardImp = (IMP)_objc_msgForward_stret;
        }
    }
    #endif
    int headerStrCount = resetTimes + 1;

    if (originalImp != msgForwardImp) {
        class_addMethod(cls, sel, msgForwardImp, types);
        SEL selB = createSelB(sel, headerStrCount);
        NSString *strSelB = NSStringFromSelector(selB);
        class_addMethod(cls, selB, originalImp, types);
        [mgr addSelValue:NSStringFromSelector(selB) forMainKey:selStr subKey:strSelB];
        object_setClass(self, cls);
    }

    IMP impA = imp;
    SEL selA = createSelA(sel, headerStrCount);
    class_addMethod(cls, selA, impA, types);

    if (!strId) {
        strId = [NSString stringWithFormat:@"%@-%@-%d", newName, selStr, resetTimes];
    }
    NSString *strSelA = NSStringFromSelector(selA);
    [mgr addSelValue:strSelA forMainKey:selStr subKey:strId];

    [[self getClassManager].selSet addObject:selStr];
    [self set_sd_resetCount:headerStrCount forSel:sel];
    [self setCurrentCallIndex:(int)[[mgr.sel_ordered_dict valueArrForKey:selStr] count] - 1 forSel:sel];
    pthread_rwlock_unlock(&[self getManagerLock]->_rw_lock3);
    return strId;
}

- (void)removeHook:(SEL)sel key:(const void *)key {
    [self removeHook:sel strId:[NSString stringWithFormat:@"%p", key]];
}

- (void)removeHook:(SEL)sel strId:(NSString *)strId {
    SDNewClassManager *mgr = [self getClassManager];
    NSString *subKey = strId;
    NSString *selStr = [mgr.sel_block_dict valueForMainKey:NSStringFromSelector(sel) subKey:subKey];
    [mgr deleteSelValue:selStr forMainKey:NSStringFromSelector(sel) subKey:subKey];
}

- (void)addGetClassImpToClass:(Class)toCls {
    Class originalCls = self.class;
    SEL clsSel = @selector(class);
    IMP clsImp = imp_implementationWithBlock((Class)^{
        return originalCls;
    });
    const char *types = method_getTypeEncoding(class_getInstanceMethod(NSObject.class, clsSel));
    class_addMethod(toCls, clsSel, clsImp, types);
}

- (void)sd_forwardInvocation:(NSInvocation *)anInvocation {
    SEL sel = anInvocation.selector;
    if ([[self getClassManager].selSet containsObject:NSStringFromSelector(sel)]) {
        NSString *selStr = NSStringFromSelector(sel);
        pthread_rwlock_rdlock(&[self getManagerLock]->_rw_lock3);
        NSArray *selsArr = [[[self getClassManager].sel_ordered_dict valueArrForKey:selStr] copy];
        NSInteger currentIndex = [self getCurrentCallIndex:sel];
#ifdef DEBUG
        NSString *tagKey = @"SDMagicHookCallOriginalKey";
        NSMutableDictionary *debugOriginalCallDict = threadStoredDict(debugOriginalCallDictKey, [self getClassManager].className);
        NSString *tagSelKey = [NSString stringWithFormat:@"SDMagicHookCallOriginalKey-%@", selStr];
        NSMutableDictionary *dubugDict = [debugOriginalCallDict valueForKey:tagSelKey];
        if (!dubugDict) {
            dubugDict = [NSMutableDictionary new];
            [debugOriginalCallDict setValue:dubugDict forKey:tagSelKey];
        }
        BOOL previousFlag = [[dubugDict valueForKey:tagKey] boolValue];
        [dubugDict setValue:@(currentIndex != 0) forKey:tagKey];
#endif
        if ([self shouldCallOriginalMethod]) {
            NSAssert(currentIndex >= 0, @"sd_forwardInvocation fatal error!");
            [self setOriginalCallFlag:false];
#ifdef DEBUG
            previousFlag = NO;
#endif
        } else {
            currentIndex = selsArr.count - 1;
        }
        SEL currentSel = NSSelectorFromString(selsArr[currentIndex]);
        anInvocation.selector = currentSel;
        [self setCurrentCallIndex:(int)--currentIndex forSel:sel];
        pthread_rwlock_unlock(&[self getManagerLock]->_rw_lock3);
        [anInvocation invoke];
#ifdef DEBUG
        if ([[dubugDict valueForKey:tagKey] boolValue]) {
            NSLog(@"Please check if you forgot to call original method for hooked method `%@` of instance `%@`.\n请检查你是否在hook了 `%@` 的 `%@` 方法之后忘记调用原始方法。 \n\n%@", selStr, self, self, selStr, [NSThread callStackSymbols]);
            if (SDMagicHookDebugFlag) {
                raise(SIGTRAP);
            }
        }
        [dubugDict setValue:@(previousFlag) forKey:tagKey];
#endif
    }
}

- (void)addObjectDeallocCallbackBlock:(ObjectDeallocCallbackBlock)block {
    if (block) {
        [[self getClassManager].deallocCallBackBlockArr addObject:block];
    }
}

@end
