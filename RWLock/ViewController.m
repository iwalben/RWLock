//
//  ViewController.m
//  RWLock
//
//  Created by iwalben on 2020/4/29.
//  Copyright © 2020 WM. All rights reserved.
//

#import "ViewController.h"
#import <pthread.h>

@interface ViewController ()
@property (assign, nonatomic) pthread_rwlock_t lock;
@end

//模拟变量保存在全局变量a数组中，需要同时进行读写操作
int a[2] = {100,200};

@implementation ViewController

- (void)viewDidLoad {
    [super viewDidLoad];
    // 初始化锁
    pthread_rwlock_init(&_lock, NULL);
    dispatch_queue_t queue = dispatch_get_global_queue(0, 0);
    for (int i = 1; i < 100; i++) {
        dispatch_async(queue, ^{
            [self read:0];
        });
        dispatch_async(queue, ^{
            [self write:i];
        });
    }
}


- (void)read:(uintptr_t)n {
    #if __arm64__ //加锁处理
        pthread_rwlock_rdlock(&_lock);
        printf("result: %d\n",a[0]);
        pthread_rwlock_unlock(&_lock);
    //x86_64位体系 （模拟器）
    #elif __x86_64__
    int result ;
        __asm__(
         "movq (%1, %2, 8),%%r9\n"
         "movq %%r9,%0\n"
         :"+m"(result)
         :"r"(a),"r"(n)
        );
    printf("读取result: %d\n",result);
    //其他体系 加锁处理
    #else
        pthread_rwlock_rdlock(&_lock);
        printf("读取result: %d\n",a[0]);
        pthread_rwlock_unlock(&_lock);
    #endif
}
- (void)write:(int)n
{
    #if __arm64__ //加锁处理
        pthread_rwlock_wrlock(&_lock);
        a[0] = n+1;
        pthread_rwlock_unlock(&_lock);
    //x86_64位体系 （模拟器）
    #elif __x86_64__
        __asm__(
         "movq %1,%%rdi\n"
         "movq $0x1,%%rsi\n"
         "addq %%rdi,%%rsi\n"
         "movq %%rsi ,%0\n"
         :"=r"(a)
         :"m"(n)
        );
    //其他体系 加锁处理
    #else
        pthread_rwlock_wrlock(&_lock);
        a[0] = n+1;
        pthread_rwlock_unlock(&_lock);
    #endif
    printf("写入result: %d\n",a[0]);
    
}
- (void)dealloc
{
    pthread_rwlock_destroy(&_lock);
}

@end


