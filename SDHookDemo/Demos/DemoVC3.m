//
//  DemoVC3.m
//  SDMagicHookDemo
//
//  Created by gaoshaodong on 2019/11/24.
//  Copyright © 2019 gaoshaodong. All rights reserved.
//

#import "DemoVC3.h"
#import <SDMagicHook.h>

static int testClassMethodTag;

@interface DemoVC3 ()

@end

@implementation DemoVC3

- (void)viewDidLoad {
    [super viewDidLoad];

    [self hookClassMethod];

    [[DemoVC3 class] testClassMethod];

    [self hookTest3];

    // 监听任意对象的dealloc
    [self addObjectDeallocCallbackBlock:^{
        printf("Will dealloc...");
    }];

    // 监听任意对象的dealloc
    [[NSObject new] addObjectDeallocCallbackBlock:^{
        printf("Will dealloc...");
    }];
}

- (void)hookClassMethod {
    [[DemoVC3 class] hookMethod:@selector(testClassMethod) key:&testClassMethodTag impBlock:^(id cls){
        [cls callOriginalMethodInBlock:^{
            [[DemoVC3 class] testClassMethod];
        }];
        printf(">> hooked testClassMethod");
    }];
}

- (void)hookTest3 {
    [self hookMethod:@selector(test3:) impBlock:^(id this, int item){
        __block NSString* res = 0;
        [this callOriginalMethodInBlock:^{
            res = [this test3:item];
        }];
        printf(">> %d >> C\n", item);
        return [NSString stringWithFormat:@"%@%@", @"C", res];
    }];

    [self hookMethod:@selector(test3:) impBlock:^(id this, int item){
        __block NSString* res = 0;
        [this callOriginalMethodInBlock:^{
            res = [this test3:item];
        }];
        printf(">> %d >> B\n", item);
        return [NSString stringWithFormat:@"%@%@", @"B", res];
    }];

    [self hookMethod:@selector(test3:) impBlock:^(id this, int item){
        __block NSString* res = 0;
        [this callOriginalMethodInBlock:^{
            res = [this test3:item];
        }];
        printf(">> %d >> A\n", item);
        return [NSString stringWithFormat:@"%@%@", @"A", res];
    }];

    for (int i = 0; i < 10; ++i) {
        dispatch_async(dispatch_get_global_queue(0, 0), ^{
            if (![[self test3:i] isEqualToString:@"ABCD"]) {
                printf("Something went wrong!");
            }
        });
    }
}

+ (void)testClassMethod {
    printf(">> %s", sel_getName(_cmd));
}

- (void)dealloc {
    [[DemoVC3 class] removeHook:@selector(testClassMethod) key:&testClassMethodTag];
}

- (NSString *)test3:(int)item {
    printf(">> %d >> D\n", item);
    return @"D";
}

@end



/*

 @interface UIButton(SDMagicHook)

 @end

 @implementation UIButton(SDMagicHook)

 - (BOOL)sd_pointInside:(CGPoint)point withEvent:(UIEvent *)event {
     BOOL res = [self sd_pointInside:point withEvent:event];
     // 在这里实现你的自定义检测逻辑
     // ......
     return res;
 }

 - (BOOL)sd2_pointInside:(CGPoint)point withEvent:(UIEvent *)event {
     BOOL res = [self sd2_pointInside:point withEvent:event];
     // 在这里实现你的自定义检测逻辑
     // ......
     return res;
 }

 @end

 @interface UIButton(SDMagicHook222)

 @end

 @implementation UIButton(SDMagicHook222)

 - (BOOL)sd_pointInside:(CGPoint)point withEvent:(UIEvent *)event {
     BOOL res = [self sd_pointInside:point withEvent:event];
     // 在这里实现你的自定义检测逻辑
     // ......
     return res;
 }

 - (BOOL)sd2_pointInside:(CGPoint)point withEvent:(UIEvent *)event {
     BOOL res = [self sd2_pointInside:point withEvent:event];
     // 在这里实现你的自定义检测逻辑
     // ......
     return res;
 }

 @end

 */
