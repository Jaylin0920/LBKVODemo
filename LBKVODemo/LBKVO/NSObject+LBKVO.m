//
// NSObject+LBKVO.h
// LBKVODemo
//
// Created by sky on 16/9/6.
// Copyright © 2016年 sky. All rights reserved.
//

#import "NSObject+LBKVO.h"
#import <objc/objc-runtime.h>

#define lbKVOClassPrefix @"LBKVO_"
#define lbAssociateArrayKey @"lbAssociateArrayKey"

@implementation NSObject (LBKVO)

#pragma mark - public method

- (void)lb_addObserver:(id)observer key:(NSString *)key callback:(LBKVOCallback)callback{
    //1. 找到key对应的setter方法，不存在其setter方法，则直接返回，无法监听
    SEL setterSelector = NSSelectorFromString([self setterForGetter:key]);
    Method setterMethod = class_getInstanceMethod([self class], setterSelector);
    if (!setterMethod) return;

    //2. 检查对象 isa 指向的类是不是一个 KVO 类。如果不是，新建一个继承原来类的子类，并把 isa 指向这个新建的子类
    Class clazz = object_getClass(self);
    NSString *className = NSStringFromClass(clazz);
    
    if (![className hasPrefix:lbKVOClassPrefix]) {
        clazz = [self lb_KVOClassWithOriginalClassName:className];//此时的 class= lbKVO_UIView
        object_setClass(self, clazz); //修改isa指针
    }
    
    //3. 检查对象的 KVO 类重写过没有这个 setter 方法。如果没有，添加重写的 setter 方法
    const char *types = method_getTypeEncoding(setterMethod);
    class_addMethod(clazz, setterSelector, (IMP)lb_setter, types);
    
    //4. 添加该观察者到观察者列表中
    //4.1 创建观察者的信息 (用于封装：观察者，被观察的 key, 和传入的 block)
    LBObserverInfo *info = [[LBObserverInfo alloc] initWithObserver:observer key:key callback:callback];
    //4.2 获取关联对象(装着所有监听者的数组)
    NSMutableArray *observers = objc_getAssociatedObject(self, lbAssociateArrayKey);
    if (!observers) {
        observers = [NSMutableArray array];
        objc_setAssociatedObject(self, lbAssociateArrayKey, observers, OBJC_ASSOCIATION_RETAIN_NONATOMIC);
    }
    
    [observers addObject:info];
}

- (void)lb_removeObserver:(id)observer key:(NSString *)key{
    NSMutableArray *observers = objc_getAssociatedObject(self, lbAssociateArrayKey);
    if (!observers) return;
    for (LBObserverInfo *info in observers) {
        if([info.key isEqualToString:key]) {
            [observers removeObject:info];
            break;
        }
    }
}

#pragma mark - assist method


/**
 *  重写setter方法, 新方法在调用原方法后, 通知每个观察者(调用传入的block)
 */
static void lb_setter(id self, SEL _cmd, id newValue){
    NSString *setterName = NSStringFromSelector(_cmd);
    NSString *getterName = [self getterForSetter:setterName];
    if (!getterName) NSLog(@"找不到getter方法");
    
    //获取旧值
    id oldValue = [self valueForKey:getterName];
    
    //调用原类的setter方法
    struct objc_super superClazz = {
        .receiver = self,
        .super_class = class_getSuperclass(object_getClass(self))
    };
    //在 Xcode 6 里，新的 LLVM 会对 objc_msgSendSuper 以及 objc_msgSend 做严格的类型检查，如果不做类型转换。Xcode 会报有 “too many arguments……” 的错误。
    ((void (*)(void *, SEL, id))objc_msgSendSuper)(&superClazz, _cmd, newValue);
    
    //找出观察者的数组, 调用对应对象的callback
    NSMutableArray *observers = objc_getAssociatedObject(self, lbAssociateArrayKey);//获取属性
    //遍历数组
    for (LBObserverInfo *info in observers) {
        if ([info.key isEqualToString:getterName]) {
            //gcd异步调用callback
            dispatch_async(dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_DEFAULT, 0), ^{
                info.callback(info.observer, getterName, oldValue, newValue);
            });
        }
    }
}


/**
 *  用className，创建一个新的子类
 */
- (Class)lb_KVOClassWithOriginalClassName:(NSString *)className{
    NSString *kvoClassName = [lbKVOClassPrefix stringByAppendingString:className];
    Class kvoClass = NSClassFromString(kvoClassName);
    
    //1. 如果kvo class存在则返回；不存在, 则创建这个类
    if (kvoClass) return kvoClass;
    Class originClass = object_getClass(self);
    kvoClass = objc_allocateClassPair(originClass, kvoClassName.UTF8String, 0);
    //   objc_allocateClassPair(Class superclass, const char *name, size_t extraBytes)
    //   添加类 superclass 类是父类   name 类的名字  size_t 类占的空间（通常为 0）
    
    //2. 修改kvo class方法的实现
    Method clazzMethod = class_getInstanceMethod(kvoClass, @selector(class));
    const char *types = method_getTypeEncoding(clazzMethod);
    class_addMethod(kvoClass, @selector(class), (IMP)lb_class, types);
    
    //3. 注册类 (在这里告诉runtime这个类的存在)
    objc_registerClassPair(kvoClass);
    
    return kvoClass;
}

/**
 *  隐藏这个子类的存在 (模仿Apple的做法, 欺骗人们这个kvo类还是原类)
 */
Class lb_class(id self, SEL cmd){
    Class clazz = object_getClass(self);
    Class superClazz = class_getSuperclass(clazz);
    return superClazz;
}


#pragma mark - private method

/**
 *  获取key的setter方法名
 *  (name -> Name -> setName:)
 */
- (NSString *)setterForGetter:(NSString *)key{
    //1. 首字母转换成大写
    unichar c = [key characterAtIndex:0];
    NSString *str = [key stringByReplacingCharactersInRange:NSMakeRange(0, 1) withString:[NSString stringWithFormat:@"%c", c-32]];
    
    //2. 最前增加set, 最后增加:
    NSString *setter = [NSString stringWithFormat:@"set%@:", str];

    return setter;
}

/**
 *  根据setter方法名返回getter方法名
 *  (setName: -> Name -> name)
 */
- (NSString *)getterForSetter:(NSString *)key{
    //1. 去掉set
    NSRange range = [key rangeOfString:@"set"];
    NSString *subStr1 = [key substringFromIndex:range.location + range.length];
    
    //2. 首字母转换成大写
    unichar c = [subStr1 characterAtIndex:0];
    NSString *subStr2 = [subStr1 stringByReplacingCharactersInRange:NSMakeRange(0, 1) withString:[NSString stringWithFormat:@"%c", c+32]];
    
    //3. 去掉最后的:
    NSRange range2 = [subStr2 rangeOfString:@":"];
    NSString *getter = [subStr2 substringToIndex:range2.location];
    
    return getter;
}

@end
