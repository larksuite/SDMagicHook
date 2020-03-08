//
//  SDNewClassManager.h
//  SDMagicHookDemo
//
//  Created by gaoshaodong on 2019/11/20.
//  Copyright © 2019 gaoshaodong. All rights reserved.
//

#import <Foundation/Foundation.h>
@class SDDict, SDOrderedDict;

NS_ASSUME_NONNULL_BEGIN

typedef void (^OnClassDisposeBlock)(void);

@interface SDNewClassManager : NSObject

@property (nonatomic, strong) NSMutableArray *classArr;
@property (nonatomic, strong) NSMutableSet *selSet;
@property (nonatomic, strong) SDDict *sel_block_dict;
@property (nonatomic, strong) SDOrderedDict *sel_ordered_dict;
@property (nonatomic, copy, readonly) NSString *randomFlag;
@property (nonatomic, strong) NSMutableDictionary *resetCountDict;
@property (nonatomic, copy) OnClassDisposeBlock onClassDispose;
@property (nonatomic, copy) NSString *className;
@property (nonatomic, strong) NSMutableArray *deallocCallBackBlockArr;
@property (nonatomic, assign) BOOL hasSetupKVO;

- (void)addSelValue:(NSString *)value forMainKey:(NSString *)selStr subKey:(NSString *)strId;
- (void)deleteSelValue:(NSString *)value forMainKey:(NSString *)selStr subKey:(NSString *)strId;

@end

NS_ASSUME_NONNULL_END
