## Theme
runtime实现的block形式的KVO

</br>


##  实现原理图
![](http://or8jbn4mz.bkt.clouddn.com/17-8-10/18450982.jpg)


## 实现原理

###（一）addObserver

<b> 1.当观察某对象A时，要确保这个 key 的 setter 方法存在。不存在其 setter 方法，则无法监听 </b>

（class_getInstanceMethod 获取 key 对应的 setter 方法，进而判断 setter 方法是否存在）
<br> </br>


<b> 2.KVO机制动态创建一个对象A当前类的子类 NSKVONotifying_A  </b>

(objc_allocateClassPair 创建子类； objc_registerClassPair 注册类)
<br> </br>


<b> 3.在其中，隐瞒这个子类的存在，欺骗人们这个kvo类还是原类 </b>

（检测：手动创建一个类 NSKVONotifying_A，会发现系统运行到注册KVO的那段代码时程序就崩溃，因为系统在注册监听的时候动态创建了名为NSKVONotifying_A的中间类，并指向这个中间类了）
<br> </br>


<b> 4.重写新类 NSKVONotifying_A 被观察属性keyPath的setter 方法，setter 方法随后负责通知观察对象属性的改变状况 </b>

（此时isa指针指向新类，因而在该对象上对 setter 的调用就会调用已重写的 setter，从而激活键值通知机制）
<br> </br>


<b> 5.添加观察者信息添加到观察者列表中：创建观察者信息、获取关联对象 </b>
<br> </br>


###（二）removeObserver
<b> 1.获取观察者列表 </b>

<b> 2.移除观察者列表中，对应key的观察者 </b>
<br> </br>

