//
//  SDClassManagerLock.h
//  SDMagicHookDemo
//
//  Created by gaoshaodong on 2019/11/20.
//  Copyright © 2019 gaoshaodong. All rights reserved.
//

#import <Foundation/Foundation.h>
#import <os/lock.h>

NS_ASSUME_NONNULL_BEGIN

@interface SDClassManagerLock : NSObject
{
    @public
    os_unfair_lock _uf_lock;
    pthread_rwlock_t _rw_lock;
    dispatch_semaphore_t _sig_lock;
    pthread_rwlock_t _rw_lock2;
    pthread_rwlock_t _rw_lock3;
}


@end

NS_ASSUME_NONNULL_END
