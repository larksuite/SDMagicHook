//
//  DemoVC2.m
//  SDMagicHookDemo
//
//  Created by gaoshaodong on 2019/11/24.
//  Copyright © 2019 gaoshaodong. All rights reserved.
//

#import "DemoVC2.h"
#import <SDMagicHook.h>
#import "SDAutoLayout.h"

static int viewWillAppearTag;

@interface DemoVC2 ()

@end

@implementation DemoVC2
{
    NSString *_viewWillDisappearTag;
    UIViewController *_rootVC;
}

- (void)viewDidLoad {
    [super viewDidLoad];

    _rootVC = self.navigationController.childViewControllers.firstObject;

    [self.view addSubview:self.textView];
    self.textView.sd_layout.spaceToSuperView(UIEdgeInsetsMake(20, 20, 20, 20));
    self.textView.text = @"";
    self.textView.editable = NO;

    _viewWillDisappearTag = @"DemoVC2_viewWillDisappearTag";

    [self doHook];

}

- (void)doHook {
    UIViewController *rootVC = _rootVC;

    __weak typeof(self) wkSelf = self;

    // 如果你hook的对象是一个全局对象，你们你最好可以在自己dealloc时候remove一下这个hook
    // 如果你想可以随时remove某个hook，那么需要你在hook时候带上一个key或者strId

    // 监听RootViewController的viewWillAppear方法
    [rootVC hookMethod:@selector(viewWillAppear:) key:&viewWillAppearTag impBlock:^(UIViewController *vc, BOOL animated){
        [vc callOriginalMethodInBlock:^{
            [vc viewWillAppear:animated];
        }];

        wkSelf.textView.text = [NSString stringWithFormat:@"%@\n\n%@ -->> viewWillAppear", wkSelf.textView.text, vc];
    }];

    // 监听RootViewController的viewWillDisappear方法
    [rootVC hookMethod:@selector(viewWillDisappear:) strId:_viewWillDisappearTag impBlock:^(UIViewController *vc, BOOL animated){
        [vc callOriginalMethodInBlock:^{
            [vc viewWillDisappear:animated];
        }];

        wkSelf.textView.text = [NSString stringWithFormat:@"%@\n\n%@ -->> viewWillDisappear", wkSelf.textView.text, vc];
    }];
}

- (void)dealloc {
    [_rootVC removeHook:@selector(viewWillAppear:) key:&viewWillAppearTag];
    [_rootVC removeHook:@selector(viewWillDisappear:) strId:_viewWillDisappearTag];
}

@end
