//
//  ViewController.m
//  PracticeRunloop
//
//  Created by guomin on 16/4/28.
//  Copyright © 2016年 iBinaryOrg. All rights reserved.
//

#import "ViewController.h"

@interface ViewController ()

@property(nonatomic,strong) NSThread *myThread;

@end

//RunLoop Mode包含以下几种:
//NSDefaultRunLoopMode,NSEventTrackingRunLoopMode,UIInitializationRunLoopMode,NSRunLoopCommonModes,NSConnectionReplyMode,NSModalPanelRunLoopMode

//每一个Mode包含可能包含soures,observer,timer，统称为Mode的item。如果一个Mode中一个item都没有，则这个RunLoop会直接退出，不进入循环。
//RunLoop要想工作，必须要让它存在一个Item(source,observer或者timer)，

@implementation ViewController

- (void)viewDidLoad {
    [super viewDidLoad];
    // Do any additional setup after loading the view, typically from a nib.
    
    //[self alwaysLiveBackGoundThread];
    [self tryTimerOnBackgroundThread];
}

- (void)didReceiveMemoryWarning {
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}

- (IBAction)buttonAction:(UIButton *)button {
//    [self mainThreadRunloop];
//    [self backgroundThreadRunloop];
//    [self mainThreadPerformSelector];
    [self backgroundThreadPerfortSelector];
}

//==================== mainThreadRunloop ====================
- (void)mainThreadRunloop {
    //主线程之所以能够一直存在，并且随时准备被唤醒就是应为系统为其添加了很多Item
    while (1) {
        NSLog(@"while begin");
        
        NSRunLoop *runloop = [NSRunLoop currentRunLoop];
        [runloop runMode:NSDefaultRunLoopMode beforeDate:[NSDate distantFuture]];
        
        NSLog(@"whild end");
    }
}

//==================== backgroundThreadRunloop ====================
- (void)backgroundThreadRunloop {
    dispatch_async(dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_DEFAULT, 0), ^{
        while (1) {
            NSLog(@"while begin");
            
            NSPort *macPort = [NSPort port];
            NSRunLoop *runloop = [NSRunLoop currentRunLoop];
            [runloop addPort:macPort forMode:NSDefaultRunLoopMode];
            [runloop runMode:NSDefaultRunLoopMode beforeDate:[NSDate distantFuture]];
            
            NSLog(@"whild end");
        }
    });
}

//==================== mainThreadPerformSelector ====================
- (void)mainThreadPerformSelector {
    [self performSelector:@selector(mainThreadSelector) withObject:nil];
}

- (void)mainThreadSelector {
    NSLog(@"execute %s",__func__);
}

//==================== backgroundThreadPerfortSelector ====================

- (void)backgroundThreadPerfortSelector {
    dispatch_async(dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_DEFAULT, 0), ^{
        //在调用performSelector:onThread:withObject:waitUntilDone的时候，系统会给我们创建一个Timer的source，加到对应的RunLoop上去，然而这个时候我们没有RunLoop.
        //所以如果想要执行backgroundThreadSelector方法，必须添加一个开启的runloop
        [self performSelector:@selector(backgroundThreadSelector) onThread:[NSThread currentThread] withObject:nil waitUntilDone:NO];
        [[NSRunLoop currentRunLoop] run];
    });
}

- (void)backgroundThreadSelector {
    NSLog(@"execute %s",__func__);
}

//==================== 一直"活着"的后台线程 ====================
- (void)alwaysLiveBackGoundThread {
    NSThread *thread = [[NSThread alloc]initWithTarget:self selector:@selector(myThreadRun) object:@"etund"];
    self.myThread = thread;
    [self.myThread start];
}

- (void)myThreadRun {
    NSLog(@"my thread run");
    
    //线程的五大状态来说明了:新建状态、就绪状态、运行状态、阻塞状态、死亡状态，这个时候尽管内存中还有线程，但是这个线程在执行完任务之后已经死亡了
    //给这个线程的RunLoop添加一个source，那么这个线程就会检测这个source等待执行，而不至于死亡
    NSRunLoop *runloop = [NSRunLoop currentRunLoop];
    [runloop addPort:[NSPort port] forMode:NSDefaultRunLoopMode];
    [runloop run];
}

- (void)touchesBegan:(NSSet<UITouch *> *)touches withEvent:(UIEvent *)event {
    NSLog(@"%@",self.myThread);
    [self performSelector:@selector(doBackGroundThreadWork) onThread:self.myThread withObject:nil waitUntilDone:NO];
}

- (void)doBackGroundThreadWork {
    NSLog(@"do some work %s",__FUNCTION__);
}

//==================== tryTimerOnBackgroundThread ====================
- (void)tryTimerOnBackgroundThread {
    
    dispatch_async(dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_DEFAULT, 0), ^{
        NSTimer *myTimer = [NSTimer scheduledTimerWithTimeInterval:0.5 target:self
                                                          selector:@selector(timerAction) userInfo:nil repeats:YES];
        
        [myTimer fire];
        
        //NSTimer,只有注册到RunLoop之后才会生效，这个注册是由系统自动给我们完成的,既然需要注册到RunLoop,那么我们就需要有一个RunLoop
        NSRunLoop *runLoop = [NSRunLoop currentRunLoop];
        [runLoop run];
    });
}

- (void)timerAction {
    
    NSLog(@"timer action");
    
}

@end
