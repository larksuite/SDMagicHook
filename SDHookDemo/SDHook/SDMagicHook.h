//
//  SDMagicHook.h
//  SDMagicHookDemo
//
//  Created by gaoshaodong on 2019/11/20.
//  Copyright © 2019 gaoshaodong. All rights reserved.
//

#import <Foundation/Foundation.h>

NS_ASSUME_NONNULL_BEGIN

typedef void(^CallOriginalMethodBlock)(void);
typedef void(^ObjectDeallocCallbackBlock)(void);

/// debug模式下会自动检查hook操作是否忘记调用原始方法，如果发现未调用原始方法会暂停当前进程帮助你定位问题，
/// 如果你不希望在检测到异常时暂停当前进程请将此tag置为NO。
extern BOOL SDMagicHookDebugFlag;

@interface NSObject(SDMagicHook)

/// strId用做hook标识，当不再需要hook时可调用removeHook方法清除hook
- (void)hookMethod:(SEL)sel strId:(NSString * _Nonnull)strId impBlock:(id)block;
/// key用做hook标识，当不再需要hook时可调用removeHook方法清除hook
- (void)hookMethod:(SEL)sel key:(const void * _Nonnull)key impBlock:(id)block;
/// file和line用作hook标识，防止重复hook，返回值NSString *为此次hook对应的key，可以使用此key随时移除hook
- (NSString *)hookMethod:(SEL)sel file:(char * _Nullable)file line:(int)line impBlock:(id)block;
// 返回值NSString *为此次hook对应的key，可以使用此key随时移除hook
- (NSString *)hookMethod:(SEL)sel impBlock:(id)block;
/// 在hook回调中调用此方法然后在blk参数中实现对原生函数的调用
- (void)callOriginalMethodInBlock:(CallOriginalMethodBlock)blk;
/// 删除hook
- (void)removeHook:(SEL)sel key:(const void * _Nonnull)key;
- (void)removeHook:(SEL)sel strId:(NSString * _Nonnull)strId;

/// 监听dealloc回调
- (void)addObjectDeallocCallbackBlock:(ObjectDeallocCallbackBlock)block;

@end

NS_ASSUME_NONNULL_END
