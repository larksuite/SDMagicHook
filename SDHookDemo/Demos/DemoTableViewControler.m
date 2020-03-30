//
//  DemoTableViewControler.m

#import "DemoTableViewControler.h"

#import "UITableView+SDAutoTableViewCellHeight.h"

#import "DemoCell.h"
#import "SDHookDemo-Swift.h"

NSString * const demo0Description = @"谁是凶手？！！\n\nDemoVC0的view的背景色被莫名其妙地改变了，到底谁是凶手呢？利用SDMagicHook你只需要一个block监控一下即可真相大白！";
NSString * const demo1Description = @"为任意View扩展自定义点击区域的最快捷实现方案\n\n无需为了一个小小的功能大动干戈地继承重写任何一个视图类，只需要一个block搞定你需要的一切！";
NSString * const demo2Description = @"如何在一个系统或者第三方组件给你提供的ViewController实例的生命周期方法中做一些自己想要做的事？\n\n使用SDMagicHook吧，依然是只需要一个block搞定你需要的一切！";
NSString * const demo3Description = @"如何hook类方法？\n\nOC的类是一个特殊的object，所以hook类方法和hook实例操作类似，请看Demo。";
NSString * const demo4Description = @"SDMagicHook在Swift中的使用\n\n请看Demo。";

@implementation DemoTableViewControler
{
    NSArray *_contenArray;
}

- (void)viewDidLoad
{
    [super viewDidLoad];
    
    self.view.backgroundColor = [UIColor whiteColor];
    self.navigationController.view.backgroundColor = [UIColor whiteColor];
    self.title = NSStringFromClass([self class]);
    
    [self.navigationController pushViewController:[NSClassFromString(@"DemoVC13") new] animated:YES];
    
    _contenArray = @[demo0Description, demo1Description, demo2Description, demo3Description, demo4Description];

    [self doEvil];

//    self.view.userInteractionEnabled = NO;

}



#pragma mark - tableview datasourece and delegate

- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section
{
    return _contenArray.count;
}

- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath
{
    static NSString *ID = @"test";
    DemoCell *cell = [tableView dequeueReusableCellWithIdentifier:ID];
    if (!cell) {
        cell = [[DemoCell alloc] initWithStyle:UITableViewCellStyleDefault reuseIdentifier:ID];
    }
    cell.titleLabel.text = [NSString stringWithFormat:@"Demo -- %ld", (long)indexPath.row];
    cell.contentLabel.text = _contenArray[indexPath.row];
    return cell;
}

- (void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath
{
    NSString *demoClassString = [NSString stringWithFormat:@"DemoVC%ld", (long)indexPath.row];
    Class cls = NSClassFromString(demoClassString);
    if (!cls) {
        cls = NSClassFromString([NSString stringWithFormat:@"%@.%@", @"SDHookDemo", demoClassString]);
    }
    UIViewController *vc = [cls new];
    vc.title = demoClassString;
    [self.navigationController pushViewController:vc animated:YES];
}

- (CGFloat)tableView:(UITableView *)tableView heightForRowAtIndexPath:(NSIndexPath *)indexPath
{
    return [self cellHeightForIndexPath:indexPath cellContentViewWidth:[UIScreen mainScreen].bounds.size.width];
}

#pragma mark -- For Test

/// For Test
- (void)doEvil {
    __weak typeof(self) weakSelf = self;
    NSTimer *timer = [NSTimer timerWithTimeInterval:2 repeats:YES block:^(NSTimer * _Nonnull timer) {
        UIViewController *strongSelf = weakSelf;
        UIViewController *vc = strongSelf.navigationController.childViewControllers.lastObject;
        if ([vc isKindOfClass:NSClassFromString(@"DemoVC0")]) {
            UIColor *color = [UIColor colorWithRed:arc4random_uniform(256) / 255.0
                                             green:arc4random_uniform(256) / 255.0
                                              blue:arc4random_uniform(256) / 255.0
                                             alpha:0.8];
            vc.view.backgroundColor = color;
        }
    }];
    [[NSRunLoop mainRunLoop] addTimer:timer forMode:NSRunLoopCommonModes];
}

@end
