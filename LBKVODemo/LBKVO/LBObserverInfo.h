//
//  LBObserverInfo.h
//  LBKVODemo
//
//  Created by JiBaoBao on 17/8/8.
//  Copyright © 2017年 JiBaoBao. All rights reserved.
//

#import <Foundation/Foundation.h>

typedef void (^LBKVOCallback)(id observer, NSString *key, id oldValue, id newValue);

@interface LBObserverInfo : NSObject

/** 监听者 */
@property (nonatomic, weak) id observer;

/** 监听的属性 */
@property (nonatomic, copy) NSString *key;

/** 回调的block */
@property (nonatomic, copy) LBKVOCallback callback;


- (instancetype)initWithObserver:(id)observer key:(NSString *)key callback:(LBKVOCallback)callback;

@end
