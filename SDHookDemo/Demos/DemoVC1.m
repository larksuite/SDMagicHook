//
//  DemoVC1.m
//  SDMagicHookDemo
//
//  Created by gaoshaodong on 2019/11/20.
//  Copyright © 2019 gaoshaodong. All rights reserved.
//

#import "DemoVC1.h"
#import <SDMagicHook.h>

@interface TestA : NSObject

- (void)test;

@end

@implementation TestA

- (void)test {
    printf("AAAAAAAAAAAAA");
}

@end

@interface TestB : TestA

@end

@implementation TestB

- (void)test {
    printf("BBBBBBBBBBBBB");
}

@end



@interface DemoVC1 ()

@end

@implementation DemoVC1
{
    int _tag;
    UIButton *_button;
    UILabel *_label;
    UIButton *_button2;
    Boolean _expand;
    NSString *_hookID;
}


// 扩大或者恢复button的点击区域
- (void)expand:(Boolean)yn {

    if (yn) {
        __weak typeof(self) weakSelf = self;
        // 扩大button的点击区域。如果你需要随时可以remove hook，你可以将hook返回的id保存下来
        _hookID = [_button hookMethod:@selector(pointInside:withEvent:) impBlock:^(UIView *v, CGPoint p, UIEvent *e){
            __block BOOL res = false;
            [v callOriginalMethodInBlock:^{
                res = [v pointInside:p withEvent:e];
            }];
            // 如果本来就在响应范围内，直接return true;
            if (res) return YES;

            return [weakSelf pointCheck:p view:v];
        }];
    } else {
        // 清除hook，恢复正常的点击区域
        [_button removeHook:@selector(pointInside:withEvent:) strId:_hookID];
    }
}


/*

- (void)expand:(Boolean)yn {

    static int btnFlag = 0;

    if (yn) {
        __weak typeof(self) weakSelf = self;
        // 扩大button的点击区域
        [_button hookMethod:@selector(pointInside:withEvent:) key:&btnFlag impBlock:^(UIView *v, CGPoint p, UIEvent *e){
            __block BOOL res = false;
            [v callOriginalMethodInBlock:^{
                res = [v pointInside:p withEvent:e];
            }];
            // 如果本来就在响应范围内，直接return true;
            if (res) return YES;

            return [weakSelf pointCheck:p view:v];
        }];
    } else {
        // 清除hook，恢复正常的点击区域
        [_button removeHook:@selector(pointInside:withEvent:) key:&btnFlag];
    }
}

*/












- (void)viewDidLoad {
    [super viewDidLoad];

    [self setupViews];


    TestA *a = [TestA new];
    NSString *atag = [a hookMethod:@selector(test) impBlock:^(typeof(a) this){
        [this callOriginalMethodInBlock:^{
            [this test];
        }];
        printf("a hookMethod:@selector(test)");
    }];
    [a test];
    [a removeHook:@selector(test) strId:atag];

    TestB *b = [TestB new];
    [b hookMethod:@selector(test) impBlock:^(typeof(b) this){
        [this callOriginalMethodInBlock:^{
            [this test];
        }];
        printf("b hookMethod:@selector(test)");
    }];
    [b test];
}

- (BOOL)pointCheck:(CGPoint)p view:(UIView *)v {
    CGRect labelFrame = _label.frame;
    CGRect btnFrame = v.frame;
    CGPoint labelOrigin = labelFrame.origin;
    CGPoint btnOrigin = btnFrame.origin;
    CGSize labelSize = labelFrame.size;
    CGFloat minX = labelOrigin.x - btnOrigin.x;
    CGFloat minY = labelOrigin.y - btnOrigin.y;
    CGFloat maxX = labelSize.width + minX;
    CGFloat maxY = labelSize.height + minY;
    return (p.x >= minX) && (p.x <= maxX) && (p.y >= minY) && (p.y <= maxY);
}

- (void)setupViews {
    CGRect labelFrame = CGRectMake(30, 30, 300, 400);
    UILabel *label = [[UILabel alloc] initWithFrame:labelFrame];
    label.layer.borderColor = [UIColor greenColor].CGColor;
    label.layer.borderWidth = 2;
    label.textColor = [UIColor greenColor];
    label.font = [UIFont boldSystemFontOfSize:20];
    label.textAlignment = NSTextAlignmentCenter;
    [self.view addSubview:label];
    _label = label;

    UIButton *btn = [[UIButton alloc] initWithFrame:CGRectMake(100, 310, 150, 100)];
    btn.backgroundColor = [UIColor greenColor];
    [btn setTitle:[NSString stringWithFormat:@"%d", _tag] forState:UIControlStateNormal];
    [btn setTitleColor:[UIColor redColor] forState:UIControlStateNormal];
    btn.titleLabel.font = [UIFont boldSystemFontOfSize:20];
    [btn addTarget:self action:@selector(test:) forControlEvents:UIControlEventTouchUpInside];
    _button = btn;
    [self.view addSubview:_button];


    _button2 = [[UIButton alloc] initWithFrame:CGRectMake(30, 500, 300, 50)];
    _button2.backgroundColor = [UIColor grayColor];
    [_button2 addTarget:self action:@selector(change) forControlEvents:UIControlEventTouchUpInside];
    [self.view addSubview:_button2];

    [self change];
}

- (void)change {
    _expand = !_expand;

    UIColor *textColor = _expand ? [UIColor greenColor] : [UIColor redColor];
    NSString *title = _expand ? @"此区域可响应button点击" : @"此区域不可响应button点击";
    _label.layer.borderColor = textColor.CGColor;
    _label.textColor = textColor;
    _label.text = title;

    [_button2 setTitle:_expand ? @"点击恢复正常的点击区域" : @"点击扩大点击区域" forState:UIControlStateNormal];
    [self expand:_expand];
}

- (void)test:(UIButton *)btn {
    [btn setTitle:[NSString stringWithFormat:@"%d", ++_tag] forState:UIControlStateNormal];
}

@end
