//
//  SocketClient+Recver.m
//  Classroom3
//
//  Created by ryan on 2017/4/24.
//  Copyright © 2017年 ryan. All rights reserved.
//

#import "SocketClient+Recver.h"

@implementation SocketClient (Recver)

- (BOOL)hasSelector:(SEL)selector {
    if (self.delegate && [self.delegate respondsToSelector:selector]) {
        return YES;
    }
    return NO;
}

- (void)recver {
    [self onRecv:@"joinSuccess" calback:^(NSArray *data) {
        NSLog(@"join sucess");
        if ([self hasSelector:@selector(onJoinSuccess:)]) {
            [self.delegate onJoinSuccess:data];
        }
    }];
    
    [self onRecv:@"leave" calback:^(NSArray *data) {
        if ([self hasSelector:@selector(onLeave)]) {
            [self.delegate onLeave];
        }
    }];
    
    [self onRecv:@"kicked" calback:^(NSArray *data) {
        if ([self hasSelector:@selector(onKicked)]) {
            [self.delegate onKicked];
        }
    }];
    
    [self onRecv:@"confirmJoin" calback:^(NSArray *data) {
        if ([self hasSelector:@selector(onConfirmJoin)]) {
            [self.delegate onConfirmJoin];
        }
    }];
    
    [self onRecv:@"newUser" calback:^(NSArray * _Nonnull data) {
        if ([self hasSelector:@selector(onNewUser)]) {
            [self.delegate onNewUser];
        }
    }];
    
    [self onRecv:@"otherUserLeave" calback:^(NSArray * _Nonnull data) {
        if ([self hasSelector:@selector(onOtherUserLeave:)]) {
            [self.delegate onOtherUserLeave:data];
        }
    }];
    
    //recv
    [self onRecv:@"rtc" calback:^(NSArray * _Nonnull data) {
        if ([self hasSelector:@selector(onRecv:)]) {
            [self.delegate onRecv:[data objectAtIndex:0]];
        }
    }];
}

@end
