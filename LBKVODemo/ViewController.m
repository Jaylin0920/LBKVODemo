//
//  ViewController.m
//  LBKVODemo
//
//  Created by JiBaoBao on 17/8/9.
//  Copyright © 2017年 JiBaoBao. All rights reserved.
//



#import "ViewController.h"
#import "NSObject+LBKVO.h"

@interface ViewController ()

@property (weak, nonatomic) IBOutlet UILabel *testLbael;

@end

@implementation ViewController

- (void)dealloc{
    [self.view lb_removeObserver:self.testLbael key:@"backgroundColor"];
    // 竟然可以这样编辑,厉害了
}

- (void)viewDidLoad {
    [super viewDidLoad];
    
    // textLabel要监听colorView的backgroundColor属性
    [self.view lb_addObserver:self.testLbael key:@"backgroundColor" callback:^(UILabel *observer, NSString *key, id oldValue, id newValue) {
        // 回到主线程刷新UI界面
        dispatch_async(dispatch_get_main_queue(), ^{
            NSLog(@"颜色改变了!");
            observer.text = [NSString stringWithFormat:@"currentBGColor = %@", newValue];
        });
    }];
}

- (void)touchesBegan:(NSSet<UITouch *> *)touches withEvent:(UIEvent *)event{
    self.view.backgroundColor = [UIColor colorWithRed:arc4random_uniform(255)/255.0 green:arc4random_uniform(255)/255.0 blue:arc4random_uniform(255)/255.0 alpha:1.0];
}


@end
