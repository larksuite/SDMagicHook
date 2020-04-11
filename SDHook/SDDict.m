//
//  SDDict.m
//  SDMagicHookDemo
//
//  Created by gaoshaodong on 2019/11/20.
//  Copyright © 2019 gaoshaodong. All rights reserved.
//

#import "SDDict.h"

@implementation SDDict
{
    NSMutableDictionary *_dict;
}

- (instancetype)init {
    if (self = [super init]) {
        _dict = [NSMutableDictionary new];
    }
    return self;
}

- (void)setValue:(id)value forMainKey:(NSString *)main subKey:(NSString *)sub {
    NSMutableDictionary *dict = _dict[main];
    if (!dict) {
        dict = [NSMutableDictionary new];
        [_dict setValue:dict forKey:main];
    }
    [dict setValue:value forKey:sub];
}

- (id)valueForMainKey:(NSString *)main subKey:(NSString *)sub {
    return _dict[main][sub];
}

@end

