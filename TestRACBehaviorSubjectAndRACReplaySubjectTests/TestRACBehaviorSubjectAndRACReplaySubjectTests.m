//
//  TestRACBehaviorSubjectAndRACReplaySubjectTests.m
//  TestRACBehaviorSubjectAndRACReplaySubjectTests
//
//  Created by ys on 2018/8/24.
//  Copyright © 2018年 ys. All rights reserved.
//

#import <XCTest/XCTest.h>

#import <ReactiveCocoa.h>

@interface TestRACBehaviorSubjectAndRACReplaySubjectTests : XCTestCase

@end

@implementation TestRACBehaviorSubjectAndRACReplaySubjectTests

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

@end
