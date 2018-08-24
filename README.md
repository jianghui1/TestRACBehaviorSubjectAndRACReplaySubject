##### 这里分析`RACSubject`的子类`RACBehaviorSubject`和`RACReplaySubject`。

下面用到的测试用例在[这里](https://github.com/jianghui1/TestRACBehaviorSubjectAndRACReplaySubject)。
***
先分析`RACBehaviorSubject`。

首先，打开`.h`文件，查看这个类的注释：

    A behavior subject sends the last value it received when it is subscribed to.
翻译如下：

    当该对象被订阅的时候，会发送他之前接收到的最后一个值。
接着是唯一的一个方法:

    /// Creates a new behavior subject with a default value. If it hasn't received
    /// any values when it gets subscribed to, it sends the default value.
    + (instancetype)behaviorSubjectWithDefaultValue:(id)value;
这是实例化对象的方法，注释翻译如下：

    用一个默认值创建一个新的对象。如果当它被订阅的时候，还没有收到任何的值，就将默认值发送出去。
其实，通过上面的介绍应该也大概了解了这个类的作用，就是当该实例被订阅的时候重新发送之前接收到的最后一个值。那是如何实现的呢？

打开`.m`文件：

    + (instancetype)behaviorSubjectWithDefaultValue:(id)value {
    	RACBehaviorSubject *subject = [self subject];
    	subject.currentValue = value;
    	return subject;
    }
初始化一个对象，并将参数默认值`value`赋值给实例变量`_currentValue`。


    - (RACDisposable *)subscribe:(id<RACSubscriber>)subscriber {
    	RACDisposable *subscriptionDisposable = [super subscribe:subscriber];
    
    	RACDisposable *schedulingDisposable = [RACScheduler.subscriptionScheduler schedule:^{
    		@synchronized (self) {
    			[subscriber sendNext:self.currentValue];
    		}
    	}];
    	
    	return [RACDisposable disposableWithBlock:^{
    		[subscriptionDisposable dispose];
    		[schedulingDisposable dispose];
    	}];
    }
重写`subscribe:`方法，还是分步骤分析：
1. 首先调用父类(`RACSubject`)的`subscribe:`方法。
2. 接着获取信号订阅调度器，在获取的调度器上将实例变量`self.currentValue`发送出去。
3. 返回一个清理对象，该清理对象的工作是 父类清理对象调用清理方法 和 上一步的调度器任务返回的清理对象调用清理方法。


    - (void)sendNext:(id)value {
    	@synchronized (self) {
    		self.currentValue = value;
    		[super sendNext:value];
    	}
    }
重写`sendNext:`方法，这里首先将`value`保存到实例变量当中，然后调用父类的`sendNext:`方法。

注意，这里发送`value`值的时候，会将`value`保存起来，等到下次`subscribe:`的时候，将其发送出去。

所以，也正如上面注释说的那样，当被订阅的时候，将接收到的最后一个信号值发送出去；如果被订阅的时候还没有收到任何的信号，就发送保存下来的默认值。

测试用例：

    - (RACSignal *)signal1
    {
        return [RACSignal createSignal:^RACDisposable *(id<RACSubscriber> subscriber) {
            [subscriber sendNext:@(1)];
            
            return [RACDisposable disposableWithBlock:^{
                NSLog(@"signal1 - die");
            }];
        }];
    }
    
    - (RACSignal *)signal2
    {
        return [RACSignal createSignal:^RACDisposable *(id<RACSubscriber> subscriber) {
            [subscriber sendNext:@(2)];
            
            return [RACDisposable disposableWithBlock:^{
                NSLog(@"signal2 - die");
            }];
        }];
    }
    
    #pragma mark - RACBehaviorSubject

    - (void)testSubscribe1
    {
        RACBehaviorSubject *subject = [RACBehaviorSubject behaviorSubjectWithDefaultValue:@(100)];
        
        [subject subscribeNext:^(id x) {
            NSLog(@"subscribe1 -- %@", x);
        }];
        
        [[self signal1] subscribe:subject];
        [[self signal2] subscribe:subject];
        
        // 打印日志：
        /*
         2018-08-24 18:10:55.902242+0800 TestRACBehaviorSubjectAndRACReplaySubject[52728:1173438] subscribe1 -- 100
         2018-08-24 18:10:55.902565+0800 TestRACBehaviorSubjectAndRACReplaySubject[52728:1173438] subscribe1 -- 1
         2018-08-24 18:10:55.902723+0800 TestRACBehaviorSubjectAndRACReplaySubject[52728:1173438] subscribe1 -- 2
         2018-08-24 18:10:55.902856+0800 TestRACBehaviorSubjectAndRACReplaySubject[52728:1173438] signal1 - die
         2018-08-24 18:10:55.903008+0800 TestRACBehaviorSubjectAndRACReplaySubject[52728:1173438] signal2 - die
         */
    }
    
    - (void)testSubscribe2
    {
        RACBehaviorSubject *subject = [RACBehaviorSubject behaviorSubjectWithDefaultValue:@(100)];
        
        [[self signal1] subscribe:subject];
        
        [subject subscribeNext:^(id x) {
            NSLog(@"subscribe2 -- %@", x);
        }];
        
        [[self signal2] subscribe:subject];
        
        // 打印日志：
        /*
         2018-08-24 18:11:44.858797+0800 TestRACBehaviorSubjectAndRACReplaySubject[52773:1176345] subscribe2 -- 1
         2018-08-24 18:11:44.859038+0800 TestRACBehaviorSubjectAndRACReplaySubject[52773:1176345] subscribe2 -- 2
         2018-08-24 18:11:44.859422+0800 TestRACBehaviorSubjectAndRACReplaySubject[52773:1176345] signal1 - die
         2018-08-24 18:11:44.859630+0800 TestRACBehaviorSubjectAndRACReplaySubject[52773:1176345] signal2 - die
         */
    }
    
    - (void)testSubscribe3
    {
        RACBehaviorSubject *subject = [RACBehaviorSubject behaviorSubjectWithDefaultValue:@(100)];
        
        [[self signal1] subscribe:subject];
        [[self signal2] subscribe:subject];
        
        [subject subscribeNext:^(id x) {
            NSLog(@"subscribe3 -- %@", x);
        }];
        
        
        // 打印日志：
        /*
         2018-08-24 18:12:56.144017+0800 TestRACBehaviorSubjectAndRACReplaySubject[52826:1179999] subscribe3 -- 2
         2018-08-24 18:12:56.145344+0800 TestRACBehaviorSubjectAndRACReplaySubject[52826:1179999] signal1 - die
         2018-08-24 18:12:56.146334+0800 TestRACBehaviorSubjectAndRACReplaySubject[52826:1179999] signal2 - die
         */
    }
    
    - (void)testSubscribe4
    {
        RACBehaviorSubject *subject = [RACBehaviorSubject behaviorSubjectWithDefaultValue:@(100)];
        
        [subject subscribeNext:^(id x) {
            NSLog(@"subscribe4 -- 1 -- %@", x);
        }];
        
        [[self signal1] subscribe:subject];
        
        [subject subscribeNext:^(id x) {
            NSLog(@"subscribe4 -- 2 -- %@", x);
        }];
        
        [[self signal2] subscribe:subject];
        
        [subject subscribeNext:^(id x) {
            NSLog(@"subscribe4 -- 3 -- %@", x);
        }];
        
        
        // 打印日志：
        /*
         2018-08-24 19:47:38.694907+0800 TestRACBehaviorSubjectAndRACReplaySubject[54853:1329906] subscribe4 -- 1 -- 100
         2018-08-24 19:47:38.695300+0800 TestRACBehaviorSubjectAndRACReplaySubject[54853:1329906] subscribe4 -- 1 -- 1
         2018-08-24 19:47:38.695459+0800 TestRACBehaviorSubjectAndRACReplaySubject[54853:1329906] subscribe4 -- 2 -- 1
         2018-08-24 19:47:38.695598+0800 TestRACBehaviorSubjectAndRACReplaySubject[54853:1329906] subscribe4 -- 1 -- 2
         2018-08-24 19:47:38.695707+0800 TestRACBehaviorSubjectAndRACReplaySubject[54853:1329906] subscribe4 -- 2 -- 2
         2018-08-24 19:47:38.695843+0800 TestRACBehaviorSubjectAndRACReplaySubject[54853:1329906] subscribe4 -- 3 -- 2
         2018-08-24 19:47:38.695975+0800 TestRACBehaviorSubjectAndRACReplaySubject[54853:1329906] signal1 - die
         2018-08-24 19:47:38.696068+0800 TestRACBehaviorSubjectAndRACReplaySubject[54853:1329906] signal2 - die
         */
    }
    
    - (void)testSubscribe5
    {
        RACSignal *signal1 = [RACSignal createSignal:^RACDisposable *(id<RACSubscriber> subscriber) {
            [subscriber sendNext:@(1)];
            [subscriber sendCompleted];
            
            return nil;
        }];
        
        RACSignal *signal2 = [RACSignal createSignal:^RACDisposable *(id<RACSubscriber> subscriber) {
            [subscriber sendNext:@(2)];
            [subscriber sendError:nil];
            
            return nil;
        }];
        
        RACBehaviorSubject *subject = [RACBehaviorSubject behaviorSubjectWithDefaultValue:@(100)];
        
        [subject subscribeNext:^(id x) {
            NSLog(@"subscribe5 -- 1 -- %@", x);
        } error:^(NSError *error) {
            NSLog(@"subscribe5 -- 1 -- error");
        } completed:^{
            NSLog(@"subscribe5 -- 1 -- completed");
        }];
        
        [signal1 subscribe:subject];
        
        [subject subscribeNext:^(id x) {
            NSLog(@"subscribe5 -- 2 -- %@", x);
        } error:^(NSError *error) {
            NSLog(@"subscribe5 -- 2 -- error");
        } completed:^{
            NSLog(@"subscribe5 -- 2 -- completed");
        }];
        
        [signal2 subscribe:subject];
        
        [subject subscribeNext:^(id x) {
            NSLog(@"subscribe5 -- 3 -- %@", x);
        } error:^(NSError *error) {
            NSLog(@"subscribe5 -- 3 -- error");
        } completed:^{
            NSLog(@"subscribe5 -- 3 -- completed");
        }];
        
        
        // 打印日志：
        /*
         2018-08-24 19:51:03.685125+0800 TestRACBehaviorSubjectAndRACReplaySubject[54976:1340522] subscribe5 -- 1 -- 100
         2018-08-24 19:51:03.685578+0800 TestRACBehaviorSubjectAndRACReplaySubject[54976:1340522] subscribe5 -- 1 -- 1
         2018-08-24 19:51:03.685755+0800 TestRACBehaviorSubjectAndRACReplaySubject[54976:1340522] subscribe5 -- 1 -- completed
         2018-08-24 19:51:03.685906+0800 TestRACBehaviorSubjectAndRACReplaySubject[54976:1340522] subscribe5 -- 2 -- 1
         2018-08-24 19:51:03.686095+0800 TestRACBehaviorSubjectAndRACReplaySubject[54976:1340522] subscribe5 -- 3 -- 1
         */
    }
    
    - (void)testSubscribe6
    {
        RACBehaviorSubject *subject = [RACBehaviorSubject behaviorSubjectWithDefaultValue:@(100)];
        
        RACDisposable *dispoable1 = [subject subscribeNext:^(id x) {
            NSLog(@"subscribe6 -- 1 -- %@", x);
        }];
        [dispoable1 dispose];
        
        [[self signal1] subscribe:subject];
        
        RACDisposable *dispoable2 = [subject subscribeNext:^(id x) {
            NSLog(@"subscribe6 -- 2 -- %@", x);
        }];
        [dispoable2 dispose];
        
        [[self signal2] subscribe:subject];
        
        RACDisposable *dispoable3 = [subject subscribeNext:^(id x) {
            NSLog(@"subscribe6 -- 3 -- %@", x);
        }];
        [dispoable3 dispose];
        
        
        // 打印日志：
        /*
         2018-08-24 20:19:32.634488+0800 TestRACBehaviorSubjectAndRACReplaySubject[56022:1422059] subscribe6 -- 1 -- 100
         2018-08-24 20:19:32.635434+0800 TestRACBehaviorSubjectAndRACReplaySubject[56022:1422059] subscribe6 -- 2 -- 1
         2018-08-24 20:19:32.635662+0800 TestRACBehaviorSubjectAndRACReplaySubject[56022:1422059] subscribe6 -- 3 -- 2
         2018-08-24 20:19:32.635801+0800 TestRACBehaviorSubjectAndRACReplaySubject[56022:1422059] signal1 - die
         2018-08-24 20:19:32.635905+0800 TestRACBehaviorSubjectAndRACReplaySubject[56022:1422059] signal2 - die
         */
    }
***
接着分析`RACReplaySubject`。

打开`.h`文件。

    /// A replay subject saves the values it is sent (up to its defined capacity)
    /// and resends those to new subscribers. It will also replay an error or
    /// completion.
翻译如下：

    该对象根据 capacity 确定保存他发送过的值的个数，并且重新发送这些值给新的订阅者。对错误信息和完成信息也是一样的。
下面是唯一的一个方法：

    /// Creates a new replay subject with the given capacity. A capacity of
    /// RACReplaySubjectUnlimitedCapacity means values are never trimmed.
    + (instancetype)replaySubjectWithCapacity:(NSUInteger)capacity;
根据`capacity`创建一个对象。`RACReplaySubjectUnlimitedCapacity`意味着所有的值都会保存下来，不会被截断。

根据上面的注释可以知道，该类是将之前接收到的值保存下来，下次被订阅的时候发送出去。而保存值的个数根据参数`capacity`确定。这又是如何实现的呢？

查看`.m`文件：

    const NSUInteger RACReplaySubjectUnlimitedCapacity = NSUIntegerMax;
这里定义`RACReplaySubjectUnlimitedCapacity`为无符号整型最大值，所以上面注释说当`capacity`为该值时，可以保留信号之前发送的所有值。

    + (instancetype)replaySubjectWithCapacity:(NSUInteger)capacity {
    	return [(RACReplaySubject *)[self alloc] initWithCapacity:capacity];
    }
调用`initWithCapacity:`完成初始化。

    - (instancetype)init {
    	return [self initWithCapacity:RACReplaySubjectUnlimitedCapacity];
    }
重写`init`方法，并调用`initWithCapacity:`完成初始化。注意这里`capacity`为`RACReplaySubjectUnlimitedCapacity`。

    - (instancetype)initWithCapacity:(NSUInteger)capacity {
    	self = [super init];
    	if (self == nil) return nil;
    	
    	_capacity = capacity;
    	_valuesReceived = (capacity == RACReplaySubjectUnlimitedCapacity ? [NSMutableArray array] : [NSMutableArray arrayWithCapacity:capacity]);
    	
    	return self;
    }
实例化对象，保存`capacity`并初始化实例变量。注意，`_valuesReceived`是`NSMutableArray`类型。

    - (RACDisposable *)subscribe:(id<RACSubscriber>)subscriber {
    	RACCompoundDisposable *compoundDisposable = [RACCompoundDisposable compoundDisposable];
    
    	RACDisposable *schedulingDisposable = [RACScheduler.subscriptionScheduler schedule:^{
    		@synchronized (self) {
    			for (id value in self.valuesReceived) {
    				if (compoundDisposable.disposed) return;
    
    				[subscriber sendNext:(value == RACTupleNil.tupleNil ? nil : value)];
    			}
    
    			if (compoundDisposable.disposed) return;
    
    			if (self.hasCompleted) {
    				[subscriber sendCompleted];
    			} else if (self.hasError) {
    				[subscriber sendError:self.error];
    			} else {
    				RACDisposable *subscriptionDisposable = [super subscribe:subscriber];
    				[compoundDisposable addDisposable:subscriptionDisposable];
    			}
    		}
    	}];
    
    	[compoundDisposable addDisposable:schedulingDisposable];
    
    	return compoundDisposable;
    }
重写`subscribe:`方法，还是分步骤分析：
1. 创建一个清理对象`compoundDisposable`。
2. 获取到信号订阅调度器，并在该调度器线程上执行一些操作：
    * 遍历`self.valuesReceived`中的值，如果第一步创建的清理对象没有做清理工作，将这些值发送出去。
    * 接着继续检验清理对象`compoundDisposable`是否已经做了清理工作。
    * 接着根据`self.hasCompleted`检验是否完成，`self.hasError`是否错误，并将相应的信息发送出去。如果没有完成也没有错误，调用父类的`subscribe:`方法做处理，并将从父类得到的清理对象添加到`compoundDisposable`当中。
3. 最后将第二步得到的清理对象添加到第一步得到的清理对象`compoundDisposable`中，并将`compoundDisposable`返回出去。

这里可以看到在该对象被订阅的时候会将之前接收到的值逐个发送出去。而且还会将完成信息、错误信息发送出去。

    - (void)sendNext:(id)value {
    	@synchronized (self) {
    		[self.valuesReceived addObject:value ?: RACTupleNil.tupleNil];
    		[super sendNext:value];
    		
    		if (self.capacity != RACReplaySubjectUnlimitedCapacity && self.valuesReceived.count > self.capacity) {
    			[self.valuesReceived removeObjectsInRange:NSMakeRange(0, self.valuesReceived.count - self.capacity)];
    		}
    	}
    }
首先将`value`保存到数组`valuesReceived`当中，然后调用父类的`sendNext:`完成信号值的发送。后面是关于`capacity`的判断，保证保存的值的个数最大为`capacity`个。

    - (void)sendCompleted {
    	@synchronized (self) {
    		self.hasCompleted = YES;
    		[super sendCompleted];
    	}
    }
先保存信号完成的状态，然后调用父类的`sendCompleted`发送完成信息。

    - (void)sendError:(NSError *)e {
    	@synchronized (self) {
    		self.hasError = YES;
    		self.error = e;
    		[super sendError:e];
    	}
    }
先保存错误信息，然后调用父类的`sendError:`发送错误信息。

测试用例：
    
    - (RACSignal *)signal1
    {
        return [RACSignal createSignal:^RACDisposable *(id<RACSubscriber> subscriber) {
            [subscriber sendNext:@(1)];
            
            return [RACDisposable disposableWithBlock:^{
                NSLog(@"signal1 - die");
            }];
        }];
    }
    
    - (RACSignal *)signal2
    {
        return [RACSignal createSignal:^RACDisposable *(id<RACSubscriber> subscriber) {
            [subscriber sendNext:@(2)];
            
            return [RACDisposable disposableWithBlock:^{
                NSLog(@"signal2 - die");
            }];
        }];
    }
    #pragma mark - RACReplaySubject
    
    - (void)testSubscribe11
    {
        RACReplaySubject *subject = [RACReplaySubject replaySubjectWithCapacity:RACReplaySubjectUnlimitedCapacity];
        
        [subject subscribeNext:^(id x) {
            NSLog(@"subscribe11 -- %@", x);
        }];
        
        [[self signal1] subscribe:subject];
        [[self signal2] subscribe:subject];
        
        // 打印日志：
        /*
         2018-08-24 19:56:03.602268+0800 TestRACBehaviorSubjectAndRACReplaySubject[55152:1354714] subscribe11 -- 1
         2018-08-24 19:56:03.603023+0800 TestRACBehaviorSubjectAndRACReplaySubject[55152:1354714] subscribe11 -- 2
         2018-08-24 19:56:03.603218+0800 TestRACBehaviorSubjectAndRACReplaySubject[55152:1354714] signal1 - die
         2018-08-24 19:56:03.603748+0800 TestRACBehaviorSubjectAndRACReplaySubject[55152:1354714] signal2 - die
         */
    }
    
    - (void)testSubscribe12
    {
        RACReplaySubject *subject = [RACReplaySubject replaySubjectWithCapacity:RACReplaySubjectUnlimitedCapacity];
        
        [[self signal1] subscribe:subject];
        
        [subject subscribeNext:^(id x) {
            NSLog(@"subscribe12 -- %@", x);
        }];
        
        [[self signal2] subscribe:subject];
        
        // 打印日志：
        /*
         2018-08-24 19:56:26.685398+0800 TestRACBehaviorSubjectAndRACReplaySubject[55176:1356040] subscribe12 -- 1
         2018-08-24 19:56:26.685652+0800 TestRACBehaviorSubjectAndRACReplaySubject[55176:1356040] subscribe12 -- 2
         2018-08-24 19:56:26.685790+0800 TestRACBehaviorSubjectAndRACReplaySubject[55176:1356040] signal1 - die
         2018-08-24 19:56:26.685898+0800 TestRACBehaviorSubjectAndRACReplaySubject[55176:1356040] signal2 - die
         */
    }
    
    - (void)testSubscribe13
    {
        RACReplaySubject *subject = [RACReplaySubject replaySubjectWithCapacity:RACReplaySubjectUnlimitedCapacity];
        
        [[self signal1] subscribe:subject];
        [[self signal2] subscribe:subject];
        
        [subject subscribeNext:^(id x) {
            NSLog(@"subscribe13 -- %@", x);
        }];
        
        
        // 打印日志：
        /*
         2018-08-24 19:56:44.591600+0800 TestRACBehaviorSubjectAndRACReplaySubject[55197:1357407] subscribe13 -- 1
         2018-08-24 19:56:44.591822+0800 TestRACBehaviorSubjectAndRACReplaySubject[55197:1357407] subscribe13 -- 2
         2018-08-24 19:56:44.591969+0800 TestRACBehaviorSubjectAndRACReplaySubject[55197:1357407] signal1 - die
         2018-08-24 19:56:44.592075+0800 TestRACBehaviorSubjectAndRACReplaySubject[55197:1357407] signal2 - die
         */
    }
    
    - (void)testSubscribe14
    {
        RACReplaySubject *subject = [RACReplaySubject replaySubjectWithCapacity:1];
        
        [[self signal1] subscribe:subject];
        [[self signal2] subscribe:subject];
        
        [subject subscribeNext:^(id x) {
            NSLog(@"subscribe14 -- 1 -- %@", x);
        }];
        
        RACReplaySubject *subject1 = [RACReplaySubject replaySubjectWithCapacity:2];
        
        [[self signal1] subscribe:subject1];
        [[self signal2] subscribe:subject1];
        
        [subject1 subscribeNext:^(id x) {
            NSLog(@"subscribe14 -- 2 -- %@", x);
        }];
        
        
        // 打印日志：
        /*
         2018-08-24 19:58:56.099454+0800 TestRACBehaviorSubjectAndRACReplaySubject[55292:1364205] subscribe14 -- 1 -- 2
         2018-08-24 19:58:56.099735+0800 TestRACBehaviorSubjectAndRACReplaySubject[55292:1364205] subscribe14 -- 2 -- 1
         2018-08-24 19:58:56.099863+0800 TestRACBehaviorSubjectAndRACReplaySubject[55292:1364205] subscribe14 -- 2 -- 2
         2018-08-24 19:58:56.100005+0800 TestRACBehaviorSubjectAndRACReplaySubject[55292:1364205] signal1 - die
         2018-08-24 19:58:56.100103+0800 TestRACBehaviorSubjectAndRACReplaySubject[55292:1364205] signal2 - die
         2018-08-24 19:58:56.100201+0800 TestRACBehaviorSubjectAndRACReplaySubject[55292:1364205] signal1 - die
         2018-08-24 19:58:56.100289+0800 TestRACBehaviorSubjectAndRACReplaySubject[55292:1364205] signal2 - die
         */
    }
    
    - (void)testSubscribe15
    {
        RACReplaySubject *subject = [RACReplaySubject replaySubjectWithCapacity:RACReplaySubjectUnlimitedCapacity];
        
        [subject subscribeNext:^(id x) {
            NSLog(@"subscribe15 -- 1 -- %@", x);
        }];
        
        [[self signal1] subscribe:subject];
        
        [subject subscribeNext:^(id x) {
            NSLog(@"subscribe15 -- 2 -- %@", x);
        }];
        
        [[self signal2] subscribe:subject];
        
        [subject subscribeNext:^(id x) {
            NSLog(@"subscribe15 -- 3 -- %@", x);
        }];
        
        
        // 打印日志：
        /*
         2018-08-24 19:59:14.161862+0800 TestRACBehaviorSubjectAndRACReplaySubject[55315:1365170] subscribe15 -- 1 -- 1
         2018-08-24 19:59:14.162120+0800 TestRACBehaviorSubjectAndRACReplaySubject[55315:1365170] subscribe15 -- 2 -- 1
         2018-08-24 19:59:14.162287+0800 TestRACBehaviorSubjectAndRACReplaySubject[55315:1365170] subscribe15 -- 1 -- 2
         2018-08-24 19:59:14.162422+0800 TestRACBehaviorSubjectAndRACReplaySubject[55315:1365170] subscribe15 -- 2 -- 2
         2018-08-24 19:59:14.162598+0800 TestRACBehaviorSubjectAndRACReplaySubject[55315:1365170] subscribe15 -- 3 -- 1
         2018-08-24 19:59:14.162716+0800 TestRACBehaviorSubjectAndRACReplaySubject[55315:1365170] subscribe15 -- 3 -- 2
         2018-08-24 19:59:14.162858+0800 TestRACBehaviorSubjectAndRACReplaySubject[55315:1365170] signal1 - die
         2018-08-24 19:59:14.162948+0800 TestRACBehaviorSubjectAndRACReplaySubject[55315:1365170] signal2 - die
         */
    }
    
    - (void)testSubscribe16
    {
        RACSignal *signal1 = [RACSignal createSignal:^RACDisposable *(id<RACSubscriber> subscriber) {
            [subscriber sendNext:@(1)];
            [subscriber sendCompleted];
            
            return nil;
        }];
        
        RACSignal *signal2 = [RACSignal createSignal:^RACDisposable *(id<RACSubscriber> subscriber) {
            [subscriber sendNext:@(2)];
            [subscriber sendError:nil];
            
            return nil;
        }];
        
        RACReplaySubject *subject = [RACReplaySubject replaySubjectWithCapacity:RACReplaySubjectUnlimitedCapacity];
        
        [subject subscribeNext:^(id x) {
            NSLog(@"subscribe6 -- 1 -- %@", x);
        } error:^(NSError *error) {
            NSLog(@"subscribe6 -- 1 -- error");
        } completed:^{
            NSLog(@"subscribe6 -- 1 -- completed");
        }];
        
        [signal1 subscribe:subject];
        
        [subject subscribeNext:^(id x) {
            NSLog(@"subscribe6 -- 2 -- %@", x);
        } error:^(NSError *error) {
            NSLog(@"subscribe6 -- 2 -- error");
        } completed:^{
            NSLog(@"subscribe6 -- 2 -- completed");
        }];
        
        [signal2 subscribe:subject];
        
        [subject subscribeNext:^(id x) {
            NSLog(@"subscribe6 -- 3 -- %@", x);
        } error:^(NSError *error) {
            NSLog(@"subscribe6 -- 3 -- error");
        } completed:^{
            NSLog(@"subscribe6 -- 3 -- completed");
        }];
        
        
        // 打印日志：
        /*
         2018-08-24 20:01:20.202103+0800 TestRACBehaviorSubjectAndRACReplaySubject[55403:1371749] subscribe6 -- 1 -- 1
         2018-08-24 20:01:20.203513+0800 TestRACBehaviorSubjectAndRACReplaySubject[55403:1371749] subscribe6 -- 1 -- completed
         2018-08-24 20:01:20.203923+0800 TestRACBehaviorSubjectAndRACReplaySubject[55403:1371749] subscribe6 -- 2 -- 1
         2018-08-24 20:01:20.204066+0800 TestRACBehaviorSubjectAndRACReplaySubject[55403:1371749] subscribe6 -- 2 -- completed
         2018-08-24 20:01:20.204386+0800 TestRACBehaviorSubjectAndRACReplaySubject[55403:1371749] subscribe6 -- 3 -- 1
         2018-08-24 20:01:20.205266+0800 TestRACBehaviorSubjectAndRACReplaySubject[55403:1371749] subscribe6 -- 3 -- completed
         */
    }
    
    - (void)testSubscribe17
    {
        RACReplaySubject *subject = [RACReplaySubject replaySubjectWithCapacity:RACReplaySubjectUnlimitedCapacity];
        
        RACDisposable *dispoable1 = [subject subscribeNext:^(id x) {
            NSLog(@"subscribe17 -- 1 -- %@", x);
        }];
        [dispoable1 dispose];
        
        [[self signal1] subscribe:subject];
        
        RACDisposable *dispoable2 = [subject subscribeNext:^(id x) {
            NSLog(@"subscribe17 -- 2 -- %@", x);
        }];
        [dispoable2 dispose];
        
        [[self signal2] subscribe:subject];
        
        RACDisposable *dispoable3 = [subject subscribeNext:^(id x) {
            NSLog(@"subscribe17 -- 3 -- %@", x);
        }];
        [dispoable3 dispose];
        
        
        // 打印日志：
        /*
         2018-08-24 20:17:53.066152+0800 TestRACBehaviorSubjectAndRACReplaySubject[55955:1416987] subscribe17 -- 2 -- 1
         2018-08-24 20:17:53.066681+0800 TestRACBehaviorSubjectAndRACReplaySubject[55955:1416987] subscribe17 -- 3 -- 1
         2018-08-24 20:17:53.067027+0800 TestRACBehaviorSubjectAndRACReplaySubject[55955:1416987] subscribe17 -- 3 -- 2
         2018-08-24 20:17:53.067294+0800 TestRACBehaviorSubjectAndRACReplaySubject[55955:1416987] signal1 - die
         2018-08-24 20:17:53.068096+0800 TestRACBehaviorSubjectAndRACReplaySubject[55955:1416987] signal2 - die
         */
    }
