//
//  BaseViewController.m
//  SDMagicHookDemo
//
//  Created by gaoshaodong on 2019/11/20.
//  Copyright © 2019 gaoshaodong. All rights reserved.
//

#import "BaseViewController.h"

@interface BaseViewController ()

@end

@implementation BaseViewController

- (void)viewDidLoad {
    [super viewDidLoad];
    // Do any additional setup after loading the view.
    self.edgesForExtendedLayout = UIRectEdgeNone;
    self.view.backgroundColor = [UIColor whiteColor];
}

- (UITextView *)textView {
    if (!_textView) {
        _textView = [UITextView new];
        _textView.font = [UIFont systemFontOfSize:12];
        _textView.backgroundColor = [UIColor clearColor];
    }
    return _textView;
}

@end
