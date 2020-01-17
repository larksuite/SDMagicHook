//
//  SDClassManagerLock.m
//  SDMagicHookDemo
//
//  Created by gaoshaodong on 2019/11/20.
//  Copyright © 2019 gaoshaodong. All rights reserved.
//

#import "SDClassManagerLock.h"
#import <pthread.h>

@implementation SDClassManagerLock

- (instancetype)init {
    if (self = [super init]) {
        self->_uf_lock = OS_UNFAIR_LOCK_INIT;
        pthread_rwlock_init(&self->_rw_lock, NULL);
        pthread_rwlock_init(&self->_rw_lock2, NULL);
        pthread_rwlock_init(&self->_rw_lock3, NULL);
        self->_sig_lock = dispatch_semaphore_create(1);
    }
    return self;
}

- (void)dealloc {
    pthread_rwlock_destroy(&self->_rw_lock);
    pthread_rwlock_destroy(&self->_rw_lock2);
    pthread_rwlock_destroy(&self->_rw_lock3);
}

@end
