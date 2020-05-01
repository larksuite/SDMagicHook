//
//  mrc.h
//  SDHookDemo
//
//  Created by gsd on 2020/2/12.
//  Copyright © 2020 gsd. All rights reserved.
//

#import <Foundation/Foundation.h>

NS_ASSUME_NONNULL_BEGIN

@interface SDMRCTool : NSObject

+ (void)object_copyIndexedIvars:(id)obj toCopy:(id)toCopy;
+ (void)copyClassIndexedIvarsCFDictionaryValue:(Class)cls from:(SEL)from to:(SEL)to;

+ (void)hookSetClassFuncJustOnce;

@end

NS_ASSUME_NONNULL_END
