# SDMagicHook

一种可以用于Objective-C 和 Swift的安全的影响范围可控的基于实例粒度的hook工具。

## 对传统swizzling的改进

传统的使用method_exchangeImplementations方式进行方法swizzling虽然操作简单但是却有很多缺陷和不足之处：

- 当进行方法swizzling时候需要新增一个class category然后添加一个新的方法
- 不同的category里面如果出现了同名方法就会造成方法冲突
- 传统的方法swizzling会对目标类的所有实例生效，但是这很多时候不是我们需要的甚至会带来各种副作用

现在 SDMagicHook 将帮你解决以上问题。

## SDMagicHook的优缺点

与传统的在category中新增一个自定义方法然后进行hook的方案对比，SDMagicHook的优缺点如下：
### 优点：
1. 只用一个block即可对任意一个实例的任意方法实现hook操作，不需要新增任何category，简洁高效，可以大大提高你调试程序的效率
2. hook的作用域可以控制在单个实例粒度内，将hook的副作用降到最低
3. 可以对任意普通实例甚至任意类进行hook操作，无论这个实例或者类是你自己生成的还是第三方提供的
4. 可以随时添加或去除者任意hook，易于对hook进行管理
### 缺点：
1. 为了保证增删hook时的线程安全，SDMagicHook进行增删hook相关的操作时在实例粒度内增加了读写锁，如果有在多线程频繁的hook操作可能会带来一点线程等待开销，但是大多数情况下可以忽略不计
2. 因为是基于实例维度的所以比较适合处理对某个类的个别实例进行hook的场景，如果你需要你的hook对某个类的所有实例都生效建议继续沿用传统方式的hook。

## 变更日志
2020.05.01 -- 发布可兼容KVO的新版本"1.2.4"

2020.03.09 -- 兼容KVO

## 使用方法

例子： hook CALayer的 `setBackgroundColor:` 方法来调试定位是谁悄悄改变了CALayer的backgroundcolor:

```objc
[self.view.layer hookMethod:@selector(setBackgroundColor:) impBlock:^(CALayer *layer, CGColorRef color){
    [layer callOriginalMethodInBlock:^{
        [layer setBackgroundColor:color];
    }];
    NSLog(@"%@", [NSString stringWithFormat:@"AHA! Catch it! Here are the clues.\n\n%@", [NSThread callStackSymbols]]);
}];
```

例子： hook UIButton的 `pointInside:withEvent:` 方法来扩大其点击区域:

```objc
- (void)expand:(Boolean)yn {

    if (yn) {
        __weak typeof(self) weakSelf = self;
        _hookID = [_button hookMethod:@selector(pointInside:withEvent:) impBlock:^(UIView *v, CGPoint p, UIEvent *e){
            __block BOOL res = false;
            [v callOriginalMethodInBlock:^{
                res = [v pointInside:p withEvent:e];
            }];
            if (res) return YES;

            return [weakSelf pointCheck:p view:v];
        }];
    } else {
        [_button removeHook:@selector(pointInside:withEvent:) strId:_hookID];
    }
}
```

例子： hook类方法:

```objc
- (void)hookClassMethod {
    [[DemoVC3 class] hookMethod:@selector(testClassMethod) key:&testClassMethodTag impBlock:^(id cls){
        [cls callOriginalMethodInBlock:^{
            [[DemoVC3 class] testClassMethod];
        }];
        printf(">> hooked testClassMethod");
    }];
}

+ (void)testClassMethod {
    printf(">> %s", sel_getName(_cmd));
}

- (void)dealloc {
    [[DemoVC3 class] removeHook:@selector(testClassMethod) key:&testClassMethodTag];
}
```

例子： 在Swift中hook UIViewController的 `viewDidDisappear:`方法:

```swift
override func viewDidLoad() {
    super.viewDidLoad()
    let imp: @convention(block) (UIViewController, Bool) -> Void = { (vc, flag) in
        vc.callOriginalMethod {
            vc.viewDidDisappear(flag)
        }
        print(vc)
    }
    rootVC = navigationController?.children.first
    hookID = rootVC?.hookMethod(#selector(UIViewController.viewDidDisappear(_:)), impBlock: imp)
}
```

## License

MIT License.




