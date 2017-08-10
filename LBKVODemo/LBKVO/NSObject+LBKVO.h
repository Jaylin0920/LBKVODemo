//
//  NSObject+LBKVO.h
//  LBKVODemo
//
//  Created by JiBaoBao on 17/8/8.
//  Copyright © 2017年 JiBaoBao. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "LBObserverInfo.h"

@interface NSObject (LBKVO)

- (void)lb_addObserver:(id)observer key:(NSString *)key callback:(LBKVOCallback)callback;

- (void)lb_removeObserver:(id)observer key:(NSString *)key;

@end
