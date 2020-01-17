//
//  SDDict.h
//  SDMagicHookDemo
//
//  Created by gaoshaodong on 2019/11/20.
//  Copyright © 2019 gaoshaodong. All rights reserved.
//

#import <Foundation/Foundation.h>

NS_ASSUME_NONNULL_BEGIN

@interface SDDict : NSObject

- (void)setValue:(id __nullable)value forMainKey:(NSString *)main subKey:(NSString *)sub;
- (id)valueForMainKey:(NSString *)main subKey:(NSString *)sub;

@end

NS_ASSUME_NONNULL_END
