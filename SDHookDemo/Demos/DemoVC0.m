//
//  DemoVC0.m
//  SDMagicHookDemo
//
//  Created by gaoshaodong on 2019/11/20.
//  Copyright © 2019 gaoshaodong. All rights reserved.
//

#import "DemoVC0.h"
#import "SDMagicHook.h"
#import "SDAutoLayout.h"

@interface DemoVC0 ()

@end

@implementation DemoVC0

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
