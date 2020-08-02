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
#import "SDMRCTool.h"
#import "fishhook.h"
#import "SDMagicHookUtils.h"
#import "SDMRCTool.h"

BOOL SDMagicHookDebugFlag = true;

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

- (BOOL)isKVOClass:(Class)cls {
    const char *clsCStrName = class_getName(cls);
    void *startPos = strstr(clsCStrName, "NSKVONotifying_");
    return startPos && startPos == clsCStrName;
}

- (BOOL)isSDMagicHookClass:(Class)cls {
    const char *clsCStrName = class_getName(cls);
    void *startPos = strstr(clsCStrName, "SDMagicHook_");
    return startPos && startPos == clsCStrName;
}

- (NSString *)hookMethod:(SEL)sel strId:(NSString *)strId imp:(IMP)imp {
    pthread_rwlock_wrlock(&[self getManagerLock]->_rw_lock3);

    [SDMRCTool hookSetClassFuncJustOnce];

    SDNewClassManager *mgr = [self getClassManager];
    Boolean isSettingTmpKVO = NO;
    if (!mgr.hasSetupKVO) {
        [self addObserver:mgr forKeyPath:@"class" options:NSKeyValueObservingOptionNew context:nil];
        mgr.hasSetupKVO = YES;
        isSettingTmpKVO = true;
    }
    NSString *selStr = NSStringFromSelector(sel);
    Class currentCls = object_getClass(self);
    Class superClass = class_getSuperclass(currentCls);
    BOOL isKVOClass = NO;
    Class kvoClass = nil;
    Class kvoOriginalClass = nil;
    if ([self isKVOClass:currentCls]) {
        isKVOClass = YES;
        kvoClass = currentCls;
        kvoOriginalClass = superClass;
    } else if ([self isKVOClass:superClass]) {
        isKVOClass = YES;
        kvoClass = superClass;
        kvoOriginalClass = class_getSuperclass(superClass);
    }

    if (strId) {
        NSString *targetSelString = [mgr.sel_block_dict valueForMainKey:selStr subKey:strId];
        if (targetSelString) {
            Method m = class_getInstanceMethod(currentCls, NSSelectorFromString(targetSelString));
            method_setImplementation(m, imp);
            return strId;
        }
    }

    NSString *newClsName = [self genNewClassNameWith:currentCls];
    int resetTimes = [self sd_resetCountForSel:sel];
    Method method = class_getInstanceMethod(currentCls, sel);
    Class newCls = NSClassFromString(newClsName);
    if (isSettingTmpKVO) {
        [self removeObserver:mgr forKeyPath:@"class"];
    }
    if (newCls == nil && newClsName) {
        newCls = [self setupNewClassWithName:newClsName currentCls:currentCls isKVOClass:isKVOClass];
    }
    if (newCls == nil) {
        return nil;
    } else if (object_getClass(self) != newCls) {
        object_setClass(self, newCls);
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
    NSString *uniqueFlag = mgr.randomFlag;
    if (originalImp != msgForwardImp) {
        class_addMethod(newCls, sel, msgForwardImp, types);
        SEL selB = createSelB(sel, headerStrCount, uniqueFlag);
        NSString *strSelB = NSStringFromSelector(selB);
        class_addMethod(newCls, selB, originalImp, types);
        [mgr addSelValue:NSStringFromSelector(selB) forMainKey:selStr subKey:strSelB];

        if (isKVOClass) {
            [self copyKVODataWith:kvoOriginalClass newClass:newCls originalSel:sel customSel:selB];
        }
    }

    IMP impA = imp;
    SEL selA = createSelA(sel, headerStrCount, uniqueFlag);
    class_addMethod(newCls, selA, impA, types);

    if (!strId) {
        strId = [NSString stringWithFormat:@"%@-%@-%d", newClsName, selStr, resetTimes];
    }
    NSString *strSelA = NSStringFromSelector(selA);
    [mgr addSelValue:strSelA forMainKey:selStr subKey:strId];

    [[self getClassManager].selSet addObject:selStr];
    [self set_sd_resetCount:headerStrCount forSel:sel];
    [self setCurrentCallIndex:(int)[[mgr.sel_ordered_dict valueArrForKey:selStr] count] - 1 forSel:sel];

    SEL addObserverSel = @selector(addObserver:forKeyPath:options:context:);
    Method addObserverMethod = class_getInstanceMethod(newCls, addObserverSel);
    BOOL shouldHookObserverMethod = method_getImplementation(addObserverMethod) != msgForwardImp;
    pthread_rwlock_unlock(&[self getManagerLock]->_rw_lock3);

    if (shouldHookObserverMethod) {
        [self hookKVOMethodWith:addObserverSel kvoClass:kvoClass newCls:newCls];
    }

    return strId;
}

- (void)hookKVOMethodWith:(SEL)addObserverSel kvoClass:(Class)kvoClass newCls:(Class)newCls {
    [self hookMethod:addObserverSel impBlock:^(typeof(self) this, id obs, NSString *keyPath, NSKeyValueObservingOptions ops, void *contex){

        [this callOriginalMethodInBlock:^{
            [this addObserver:obs forKeyPath:keyPath options:ops context:contex];
        }];

        // copy KVO data
        Class currentClass = object_getClass(this);
        Class kvoCls = class_getSuperclass(currentClass);
        Class kvoOriginalCls = class_getSuperclass(kvoCls);
        NSString *property = [keyPath componentsSeparatedByString:@"."].lastObject;
        if (property) {
            NSString *first = [[property substringToIndex:1] uppercaseString];
            property = [NSString stringWithFormat:@"set%@%@:", first, [property substringFromIndex:1]];
            NSArray *selsArr = [[[this getClassManager].sel_ordered_dict valueArrForKey:property] copy];
            SEL originalSel = NSSelectorFromString(property);
            SEL customSel = NSSelectorFromString(selsArr.firstObject);
            if (customSel) {
                [this copyKVODataWith:kvoOriginalCls
                             newClass:currentClass
                          originalSel:originalSel
                            customSel:customSel];
                Method originalMethod = class_getInstanceMethod(kvoCls, originalSel);
                class_replaceMethod(newCls, customSel, method_getImplementation(originalMethod), method_getTypeEncoding(originalMethod));
            }
        }
    }];
}

- (void)copyKVODataWith:(Class)kvoOriginalClass newClass:(Class)newCls originalSel:(SEL)sel customSel:(SEL)selB {
    Method method = class_getInstanceMethod(kvoOriginalClass, sel);
    [SDMRCTool copyClassIndexedIvarsCFDictionaryValue:newCls from:sel to:selB];
    class_addMethod(kvoOriginalClass, selB, method_getImplementation(method), method_getTypeEncoding(method));
}

- (NSString *)genNewClassNameWith:(Class)currentCls {
    NSString *newClsName = nil;
    const char *currentClsName = class_getName(currentCls);
    if (![self isSDMagicHookClass:currentCls]) {
        newClsName = [NSString stringWithFormat:@"SDMagicHook_%s_%@", currentClsName, [self getClassManager].randomFlag];
    } else {
        newClsName = [NSString stringWithUTF8String:currentClsName];
    }
    return newClsName;
}

- (Class)setupNewClassWithName:(NSString *)newClsName currentCls:(Class)currentCls  isKVOClass:(BOOL)isKVOClass {
    Class newCls = NSClassFromString(newClsName);
    if (!newCls && (newCls = objc_allocateClassPair(currentCls, newClsName.UTF8String, 0x68))) {
        NSAssert(newCls, @"Fatal SDMagicHookError, class generation faild!");
        SEL forwardSel = @selector(forwardInvocation:);
        Method sdForwardMethod = class_getInstanceMethod([NSObject class], @selector(sd_forwardInvocation:));
        class_addMethod(newCls, forwardSel, method_getImplementation(sdForwardMethod), method_getTypeEncoding(sdForwardMethod));
        [self addGetClassImpToClass:newCls];
        objc_registerClassPair(newCls);
        if (isKVOClass) {
            [SDMRCTool object_copyIndexedIvars:newCls toCopy:currentCls];
        }
        SDNewClassManager *mgr = [self getClassManager];
        mgr.className = newClsName;
        [mgr.classArr addObject:newCls];
        mgr.onClassDispose = ^{
            NSThread *main = [NSThread mainThread];
            NSArray *keys = @[currentCallIndexDictKey, originalCallFlagDictKey, debugOriginalCallDictKey, keyForOriginalCallFlag];
            NSMutableDictionary *dict = main.threadDictionary;
            [keys enumerateObjectsUsingBlock:^(NSString * _Nonnull key, NSUInteger idx, BOOL * _Nonnull stop) {
                if ([dict valueForKey:entryForThreadStoredDict(key, newClsName)] == nil) {
                    *stop = YES;
                    return;
                }
                [dict removeObjectForKey:entryForThreadStoredDict(key, newClsName)];
            }];
        };
    }

    if (newCls == nil) {
        return nil;
    }
    object_setClass(self, newCls);
    return newCls;
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
