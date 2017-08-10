//
//  LBObserverInfo.m
//  LBKVODemo
//
//  Created by JiBaoBao on 17/8/8.
//  Copyright © 2017年 JiBaoBao. All rights reserved.
//

#import "LBObserverInfo.h"

@implementation LBObserverInfo

- (instancetype)initWithObserver:(id)observer key:(NSString *)key callback:(LBKVOCallback)callback{
    if (self = [super init]) {
        _observer = observer;
        _key = key;
        _callback = callback;
    }
    return self;
}

@end
