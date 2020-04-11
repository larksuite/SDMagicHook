//
//  SDOrderedDict.m
//  SDMagicHookDemo
//
//  Created by gaoshaodong on 2019/11/20.
//  Copyright © 2019 gaoshaodong. All rights reserved.
//

#import "SDOrderedDict.h"

@implementation SDOrderedDict
{
    NSMutableDictionary *_dict;
}

- (instancetype)init {
    if (self = [super init]) {
        _dict = [NSMutableDictionary new];
    }
    return self;
}

- (void)addValue:(id)value withKey:(NSString *)key {
    NSMutableArray *arr = _dict[key];
    if (!arr) {
        arr = [NSMutableArray new];
        [_dict setValue:arr forKey:key];
    }
    if (value) {
        [arr addObject:value];
    }
}

- (void)deleteValue:(id)value withKey:(NSString *)key {
    NSMutableArray *arr = _dict[key];
    for (NSInteger i = 0; i < arr.count; ++i) {
        if ([arr[i] isEqualToString:value]) {
            [arr removeObjectAtIndex:i];
            break;
        }
    }
}

- (NSArray *)valueArrForKey:(NSString *)key {
    return [_dict[key] copy];
}

@end
