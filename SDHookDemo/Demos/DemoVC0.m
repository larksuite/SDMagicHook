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
    
    [self kovCompatibilityTest0];
    [self kovCompatibilityTest1];
    [self kovCompatibilityTest2];
    [self kovCompatibilityTest3];
    [self kovCompatibilityTest4];

    [self.view addSubview:self.textView];
    self.textView.sd_layout.spaceToSuperView(UIEdgeInsetsMake(20, 20, 20, 20));

    UIButton *btn = [UIButton new];
    [self.view addSubview:btn];
    [btn setTitle:@"Cath it!" forState:UIControlStateNormal];
    [btn addTarget:self action:@selector(findOutTheOneWhoChangesMyBackgroudcolor:) forControlEvents:UIControlEventTouchUpInside];
    btn.backgroundColor = UIColor.redColor;
    btn.frame = CGRectMake(100, 100, 200, 30);
    
    self.view.hidden = false;
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
    [self.view.layer hookMethod:@selector(setBackgroundColor:) impBlock:^(CALayer *this, CGColorRef color){
        [this callOriginalMethodInBlock:^{
            [this setBackgroundColor:color];
        }];
        [wkSelf showString:[NSString stringWithFormat:@"AHA! Catch it! Here are the clues.\n\n%@", [NSThread callStackSymbols]]];
    }];
    
    [self.view.layer addObjectDeallocCallbackBlock:^{
        printf("layer dealloced");
    }];
}

- (void)showString:(NSString *)str {
    self.textView.text = str;
}

- (void)kovCompatibilityTest0 {
    
    [self.view hookMethod:@selector(setFrame:) impBlock:^(UIView *this, CGRect frame){
        [this callOriginalMethodInBlock:^{
            this.frame = frame;
        }];
        NSLog(@">>> hook 0-1 %@", [NSValue valueWithCGRect:frame]);
    }];
    
    [self.view addObserver:self forKeyPath:@"frame" options:NSKeyValueObservingOptionNew context:@"Observer 0"];
    
    [self.view hookMethod:@selector(setFrame:) impBlock:^(UIView *this, CGRect frame){
        [this callOriginalMethodInBlock:^{
            this.frame = frame;
        }];
        NSLog(@">>> hook 0-2 %@", [NSValue valueWithCGRect:frame]);
    }];
    
    [self.view removeObserver:self forKeyPath:@"frame"];
    
}

- (void)kovCompatibilityTest1 {
    
    [self.view hookMethod:@selector(setFrame:) impBlock:^(UIView *this, CGRect frame){
        [this callOriginalMethodInBlock:^{
            this.frame = frame;
        }];
        NSLog(@">>> hook1 %@", [NSValue valueWithCGRect:frame]);
    }];
    
    [self.view addObserver:self forKeyPath:@"frame" options:NSKeyValueObservingOptionNew context:@"Observer 1"];
    
    [self.view hookMethod:@selector(setFrame:) impBlock:^(UIView *this, CGRect frame){
        [this callOriginalMethodInBlock:^{
            this.frame = frame;
        }];
        NSLog(@">>> hook2 %@", [NSValue valueWithCGRect:frame]);
    }];
    
}

- (void)kovCompatibilityTest2 {
    
    [self.view addObserver:self forKeyPath:@"frame" options:NSKeyValueObservingOptionNew context:@"Observer 2"];
    
    [self.view hookMethod:@selector(setFrame:) impBlock:^(UIView *this, CGRect frame){
        [this callOriginalMethodInBlock:^{
            this.frame = frame;
        }];
        NSLog(@">>> hook3 %@", [NSValue valueWithCGRect:frame]);
    }];
    
    [self.view hookMethod:@selector(setFrame:) impBlock:^(UIView *this, CGRect frame){
        [this callOriginalMethodInBlock:^{
            this.frame = frame;
        }];
        NSLog(@">>> hook4 %@", [NSValue valueWithCGRect:frame]);
    }];
    
}

- (void)kovCompatibilityTest3 {
    
    [self.view addObserver:self forKeyPath:@"frame" options:NSKeyValueObservingOptionNew context:@"Observer 3"];
    
    [self.view hookMethod:@selector(setFrame:) impBlock:^(UIView *this, CGRect frame){
        [this callOriginalMethodInBlock:^{
            this.frame = frame;
        }];
        NSLog(@">>> hook5 %@", [NSValue valueWithCGRect:frame]);
    }];
    
    [self.view addObserver:self forKeyPath:@"frame" options:NSKeyValueObservingOptionNew context:@"Observer 4"];
    
    [self.view hookMethod:@selector(setFrame:) impBlock:^(UIView *this, CGRect frame){
        [this callOriginalMethodInBlock:^{
            this.frame = frame;
        }];
        NSLog(@">>> hook6 %@", [NSValue valueWithCGRect:frame]);
    }];
    
    [self.view addObserver:self forKeyPath:@"frame" options:NSKeyValueObservingOptionNew context:@"Observer 5"];
    
}

- (void)kovCompatibilityTest4 {
    
    [self.view addObserver:self forKeyPath:@"hidden" options:NSKeyValueObservingOptionNew context:@"Observer 6"];
    
    [self.view hookMethod:@selector(setHidden:) impBlock:^(UIView *this, Boolean hidden){
        [this callOriginalMethodInBlock:^{
            this.hidden = hidden;
        }];
        NSLog(@">>> hook7 %d", hidden);
    }];
    
    [self.view addObserver:self forKeyPath:@"hidden" options:NSKeyValueObservingOptionNew context:@"Observer 7"];
    
    [self.view hookMethod:@selector(setHidden:) impBlock:^(UIView *this, Boolean hidden){
        [this callOriginalMethodInBlock:^{
            this.hidden = hidden;
        }];
        NSLog(@">>> hook8 %d", hidden);
    }];
    
}

- (void)observeValueForKeyPath:(NSString *)keyPath ofObject:(id)object change:(NSDictionary<NSKeyValueChangeKey,id> *)change context:(void *)context {
    NSLog(@">>> kvo %@, %@", context, change);
}

- (void)dealloc {
    [self.view removeObserver:self forKeyPath:@"frame"];
}

@end
