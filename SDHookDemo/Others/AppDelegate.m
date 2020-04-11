//
//  AppDelegate.m
//  SDMagicHookDemo
//
//  Created by gaoshaodong on 2019/11/20.
//  Copyright © 2019 gaoshaodong. All rights reserved.
//

#import "AppDelegate.h"
#import <SDMagicHook.h>

@interface Test : NSObject
@property (nonatomic, assign) int num;
@property (nonatomic, assign) int height;
@end

@implementation Test

- (void)setNum:(int)num {
    _num = num;
}

@end

@interface AppDelegate ()

@end

@implementation AppDelegate
{
    Test *_test;
}

- (BOOL)application:(UIApplication *)application didFinishLaunchingWithOptions:(NSDictionary *)launchOptions {

    _test = [Test new];
    [_test addObserver:self forKeyPath:@"num" options:NSKeyValueObservingOptionNew context:nil];
//    _test.num = 10;
//
//    _test.num = 1122;


//    [_test willChangeValueForKey:@"num"];
//    [_test didChangeValueForKey:@"num"];


//    [_test hookMethod:@selector(setHeight:) impBlock:^(typeof(self->_test) this, int height) {
//        [this callOriginalMethodInBlock:^{
//            [this setHeight:height];
//        }];
//    }];

    [_test addObserver:self forKeyPath:@"height" options:NSKeyValueObservingOptionNew context:nil];

    _test.height = 100;

    return YES;
}

- (void)observeValueForKeyPath:(NSString *)keyPath ofObject:(id)object change:(NSDictionary<NSKeyValueChangeKey,id> *)change context:(void *)context {
    NSLog(@">> %@, %@", keyPath, change);
}


#pragma mark - UISceneSession lifecycle

- (void)touchesBegan:(NSSet<UITouch *> *)touches withEvent:(UIEvent *)event {
    _test.num++;
}


@end
