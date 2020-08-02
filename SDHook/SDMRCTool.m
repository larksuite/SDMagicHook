//
//  mrc.m
//  SDHookDemo
//
//  Created by gsd on 2020/2/12.
//  Copyright © 2020 gsd. All rights reserved.
//

#import "SDMRCTool.h"
#include <objc/runtime.h>
#import "SDMagicHookUtils.h"
#import <fishhook/fishhook.h>

Class _Nullable (*sd_original_setclass) (id _Nullable obj, Class _Nonnull cls);

Class _Nullable sd_magichook_set_calss(id _Nullable obj, Class _Nonnull cls) {

    Class originalClass = object_getClass(obj);
    if (sd_ifClassIsSDMagicClass(originalClass) && !sd_ifClassIsSDMagicClass(cls)) {
        return originalClass;
    } else {
        return sd_original_setclass(obj, cls);
    }
}

@implementation SDMRCTool

+ (void)object_copyIndexedIvars:(id)obj toCopy:(id)toCopy {
    uint64_t *target = object_getIndexedIvars(toCopy);
    uint64_t *current = object_getIndexedIvars(obj);
    memcpy(current, target, 0x68);
}

+ (void)copyClassIndexedIvarsCFDictionaryValue:(Class)cls from:(SEL)from to:(SEL)to {
    int64_t *indexedIvars = object_getIndexedIvars(cls);
    CFMutableDictionaryRef dict = (CFMutableDictionaryRef)(*(indexedIvars + 3));
    const void *value = CFDictionaryGetValue(dict, sel_getName(from));
    if (value) {
        CFDictionaryAddValue(dict, sel_getName(to), value);
    } 
}

+ (void)hookSetClassFuncJustOnce {
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        rebind_symbols((struct rebinding[1]){{"object_setClass", sd_magichook_set_calss, (void *)&sd_original_setclass}}, 1);
    });
}

@end
