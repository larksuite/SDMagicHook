//
//  DemoVC0.m
//  SDMagicHookDemo
//
//  Created by gaoshaodong on 2019/11/20.
//  Copyright © 2019 gaoshaodong. All rights reserved.
//

#import "DemoVC0.h"
#import <SDMagicHook.h>
#import "SDAutoLayout.h"
#import <objc/runtime.h>


@interface A : NSObject
- (void)foo;
@end

@implementation A
- (void)foo {
    NSLog(@"%s", __PRETTY_FUNCTION__);
}
@end

@interface B : A @end

@implementation B
- (void)foo {
    NSLog(@"%s", __PRETTY_FUNCTION__);
    [super foo];
}
@end




@interface DemoVC0 ()

@property (nonatomic, assign) int num;
@property (nonatomic, assign) int age;

@end

@implementation DemoVC0
{
    NSTimer *_t1;
    NSTimer *_t2;
}

- (void)setNum:(int)num {
    _num = num;
}

- (void)setAge:(int)age {
    _age = age;
}

- (instancetype)initWithNibName:(NSString *)nibNameOrNil bundle:(NSBundle *)nibBundleOrNil {
    if ([super initWithNibName:nibNameOrNil bundle:nibBundleOrNil]) {

    }
    return self;
}

- (void)viewDidLoad {
    [super viewDidLoad];

    [self.view addSubview:self.textView];
    self.textView.sd_layout.spaceToSuperView(UIEdgeInsetsMake(20, 20, 20, 20));

    UIButton *btn = [UIButton new];
    [self.view addSubview:btn];
    [btn setTitle:@"Cath it!" forState:UIControlStateNormal];
    [btn addTarget:self action:@selector(findOutTheOneWhoChangesMyBackgroudcolor:) forControlEvents:UIControlEventTouchUpInside];
    btn.backgroundColor = UIColor.redColor;
    btn.frame = CGRectMake(100, 100, 200, 30);


    [self addObserver:self forKeyPath:@"num" options:NSKeyValueObservingOptionNew context:nil];

//    [self hookMethod:@selector(setAge:) impBlock:^(typeof(self) vc, int age){
//        [vc callOriginalMethodInBlock:^{
//            vc.age = age;
//        }];
//        NSLog(@">> %d", age);
//    }];
//
//    [self hookMethod:@selector(setAge:) impBlock:^(typeof(self) vc, int age){
//        [vc callOriginalMethodInBlock:^{
//            vc.age = age;
//        }];
//        NSLog(@">> %d", age);
//    }];

    [self addObserver:self forKeyPath:@"num" options:NSKeyValueObservingOptionNew context:nil];

//    [self hookMethod:@selector(setNum:) impBlock:^(typeof(self) vc, int num) {
//        [vc callOriginalMethodInBlock:^{
//            vc.num = num;
//        }];
//        NSLog(@">> %d", num);
//    }];
//
//    [self hookMethod:@selector(setNum:) impBlock:^(typeof(self) vc, int num) {
//        [vc callOriginalMethodInBlock:^{
//            vc.num = num;
//        }];
//        NSLog(@">> %d", num);
//    }];
//
//    [self hookMethod:@selector(setNum:) impBlock:^(typeof(self) vc, int num) {
//        [vc callOriginalMethodInBlock:^{
//            vc.num = num;
//        }];
//        NSLog(@">> %d", num);
//    }];
//
//    [self hookMethod:@selector(setNum:) impBlock:^(typeof(self) vc, int num) {
//        [vc callOriginalMethodInBlock:^{
//            vc.num = num;
//        }];
//        NSLog(@">> %d", num);
//    }];
    
    [self addObserver:self forKeyPath:@"age" options:NSKeyValueObservingOptionNew context:nil];
    [self addObserver:self forKeyPath:@"num" options:NSKeyValueObservingOptionNew context:nil];

//    [self aspect_hookSelector:@selector(setAge:) withOptions:AspectPositionAfter usingBlock:^(id<AspectInfo> info, int aa){
//        printf(">>>> %d", aa);
//    } error:nil];

//    [self addObserver:self forKeyPath:@"age" options:NSKeyValueObservingOptionNew context:nil];
//    [self addObserver:self forKeyPath:@"num" options:NSKeyValueObservingOptionNew context:nil];
//
//
//    A *a = [A new];
//    [a hookMethod:@selector(foo) impBlock:^(typeof(a) this){
//        [this callOriginalMethodInBlock:^{
//            [this foo];
//        }];
//    }];
//    B *b = [B new];
//    [b hookMethod:@selector(foo) impBlock:^(typeof(b) this){
//        [this callOriginalMethodInBlock:^{
//            [this foo];
//        }];
//    }];
//
//    [a foo];
//    [b foo];

    _t1 = [NSTimer timerWithTimeInterval:1 target:self selector:@selector(test1) userInfo:nil repeats:YES];

//    _t2 = [NSTimer timerWithTimeInterval:1 target:self selector:@selector(test2) userInfo:nil repeats:YES];

    [[NSRunLoop mainRunLoop] addTimer:_t1 forMode:NSRunLoopCommonModes];
//    [[NSRunLoop mainRunLoop] addTimer:_t2 forMode:NSRunLoopCommonModes];
}

- (void)test1 {
    static int a = 1;
    dispatch_async(dispatch_get_global_queue(0, 0), ^{
        self.num = 100000 + a;
        self.age = 200000 + a;
        ++a;
        NSLog(@"------------------------------");
    });
}

- (void)test2 {
    static int a = 1;
    dispatch_async(dispatch_get_global_queue(0, 0), ^{
        [self addObserver:self forKeyPath:@"age" options:NSKeyValueObservingOptionNew context:nil];
        [self addObserver:self forKeyPath:@"num" options:NSKeyValueObservingOptionNew context:nil];
        NSLog(@"AAAAAAAAAAAAAAAAAAAAAAAAAAAAA %d", a++);
    });
}

- (void)observeValueForKeyPath:(NSString *)keyPath ofObject:(id)object change:(NSDictionary<NSKeyValueChangeKey,id> *)change context:(void *)context {
    NSLog(@">> %@ >> %@", keyPath, change);
}

- (void)touchesBegan:(NSSet<UITouch *> *)touches withEvent:(UIEvent *)event {
    self.num = 11;
    self.age = 12;
    [self test2];
}

- (void)findOutTheOneWhoChangesMyBackgroudcolor:(UIButton *)btn {
    btn.hidden = YES;

    __weak typeof(self) wkSelf = self;

    // hook view的setBackgroundColor方法，看是否有人直接改了view的背景色
    // 但是你其实可以直接hook view.layer的setBackgroundColor方法，因为
    // 调用view的setBackgroundColor方法最终还是会调用view.layer的setBackgroundColor方法
    /*
    [self.view hookMethod:@selector(setBackgroundColor:) impBlock:^(UIView *v, UIColor *color){
        [v callOriginalMethodInBlock:^{
            [v setBackgroundColor:color];
        }];
        [wkSelf showString:[NSString stringWithFormat:@"AHA! Catch it! Here are the clues.\n\n%@", [NSThread callStackSymbols]]];
    }];
     */



    // hook view.layer的setBackgroundColor方法，看是否有人直接或者间接改了view.layer的背景色
    [self.view.layer hookMethod:@selector(setBackgroundColor:) impBlock:^(CALayer *layer, CGColorRef color){
        [layer callOriginalMethodInBlock:^{
            [layer setBackgroundColor:color];
        }];
        [wkSelf showString:[NSString stringWithFormat:@"AHA! Catch it! Here are the clues.\n\n%@", [NSThread callStackSymbols]]];
    }];
}

- (void)showString:(NSString *)str {
    self.textView.text = str;
}

@end
