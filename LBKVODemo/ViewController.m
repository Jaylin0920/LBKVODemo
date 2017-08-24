//
//  ViewController.m
//  LBKVODemo
//
//  Created by JiBaoBao on 17/8/9.
//  Copyright © 2017年 JiBaoBao. All rights reserved.
//

#import "ViewController.h"
#import "NSObject+LBKVO.h"

#define kKeyPath @"backgroundColor"

@interface ViewController ()

@property (weak, nonatomic) IBOutlet UILabel *testLbael;

@end

@implementation ViewController

- (void)dealloc{
    [self.view removeObserver:self forKeyPath:@"backgroundColor" context:nil];
    [self.view lb_removeObserver:self.testLbael key:kKeyPath];
}

- (void)viewDidLoad {
    [super viewDidLoad];
    
    //方法1 系统kvo
//    [self useKVO_system];
    
    //方法2 自定义kvo(blcok形式)
    [self useKVO_LB];
}

- (void)touchesBegan:(NSSet<UITouch *> *)touches withEvent:(UIEvent *)event{
    self.view.backgroundColor = [UIColor colorWithRed:arc4random_uniform(255)/255.0 green:arc4random_uniform(255)/255.0 blue:arc4random_uniform(255)/255.0 alpha:1.0];
    self.testLbael.text = @"123";
}


#pragma mark - system KVO

- (void)useKVO_system{
    [self.view addObserver:self forKeyPath:@"backgroundColor" options:NSKeyValueObservingOptionNew context:nil];
}

// 系统KVO 接收方法
- (void)observeValueForKeyPath:(NSString *)keyPath ofObject:(id)object change:(NSDictionary<NSKeyValueChangeKey,id> *)change context:(void *)context{
    NSLog(@"useKVO_system");
}


#pragma mark - LB KVO

- (void)useKVO_LB{
    // textLabel要监听colorView的backgroundColor属性
    [self.view lb_addObserver:self.testLbael key:kKeyPath callback:^(UILabel *observer, NSString *key, id oldValue, id newValue) {
            NSLog(@"useKVO_LB");
        // 回到主线程刷新UI界面
        dispatch_async(dispatch_get_main_queue(), ^{
            observer.text = [NSString stringWithFormat:@"currentBGColor = %@", newValue];
        });
    }];
}



@end
