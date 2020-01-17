//
//  SDNewClassManager.m
//  SDMagicHookDemo
//
//  Created by gaoshaodong on 2019/11/20.
//  Copyright © 2019 gaoshaodong. All rights reserved.
//

#import "SDNewClassManager.h"
#import "SDDict.h"
#import "SDOrderedDict.h"
#import <objc/runtime.h>
#import "SDMagicHook.h"

@implementation SDNewClassManager

- (instancetype)init {
    if (self = [super init]) {
        _classArr = [NSMutableArray new];
        _selSet = [NSMutableSet new];
        _sel_block_dict = [SDDict new];
        _sel_ordered_dict = [SDOrderedDict new];
        _randomFlag = arc4random_uniform(99999999);
        _resetCountDict = [NSMutableDictionary new];
        _deallocCallBackBlockArr = [NSMutableArray new];
    }
    return self;
}

- (void)dealloc {
    NSMutableArray *tmp = [_classArr mutableCopy];
    OnClassDisposeBlock blk = self.onClassDispose;
    [_deallocCallBackBlockArr enumerateObjectsUsingBlock:^(ObjectDeallocCallbackBlock _Nonnull obj, NSUInteger idx, BOOL * _Nonnull stop) {
        obj();
    }];
    dispatch_after(dispatch_time(DISPATCH_TIME_NOW, (int64_t)(0.5 * NSEC_PER_SEC)), dispatch_get_main_queue(), ^{
        if (blk) {
            blk();
        }
        for (int i = 0; i < tmp.count; ++i) {
            Class cls = [tmp lastObject];
            [tmp removeLastObject];
            objc_disposeClassPair(cls);
        }
    });
}

- (void)addSelValue:(NSString *)value forMainKey:(NSString *)selStr subKey:(NSString *)strId {
    [_sel_block_dict setValue:value forMainKey:selStr subKey:strId];
    [_sel_ordered_dict addValue:value withKey:selStr];
}

- (void)deleteSelValue:(NSString *)value forMainKey:(NSString *)selStr subKey:(NSString *)strId {
    [_sel_block_dict setValue:nil forMainKey:selStr subKey:strId];
    [_sel_ordered_dict deleteValue:value withKey:selStr];
}

@end
