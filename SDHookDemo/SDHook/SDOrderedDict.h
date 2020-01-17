//
//  SDOrderedDict.h
//  SDMagicHookDemo
//
//  Created by gaoshaodong on 2019/11/20.
//  Copyright © 2019 gaoshaodong. All rights reserved.
//

#import <Foundation/Foundation.h>

NS_ASSUME_NONNULL_BEGIN

@interface SDOrderedDict : NSObject

- (void)addValue:(id)value withKey:(NSString *)key;
- (void)deleteValue:(id)value withKey:(NSString *)key;
- (NSArray *)valueArrForKey:(NSString *)key;

@end

NS_ASSUME_NONNULL_END
