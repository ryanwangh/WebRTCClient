//
//  SocketClient.m
//  Classroom3
//
//  Created by ryan on 2017/4/24.
//  Copyright © 2017年 ryan. All rights reserved.
//

#import "SocketClient.h"
#import "SocketClient+Recver.h"

@implementation SocketConfig

+ (instancetype)defaultConfig {
    return [SocketConfig configWithPath:nil
                           reconnection:YES
                   reconnectionAttempts:5
                      reconnectionDelay:2000
                   reconnectionDelayMax:10000
                                timeout:40000];
}

+ (instancetype)configWithPath:(NSString *)path
                  reconnection:(BOOL)reconnection
          reconnectionAttempts:(NSUInteger)reconnectionAttempts
             reconnectionDelay:(NSUInteger)reconnectionDelay
          reconnectionDelayMax:(NSUInteger)reconnectionDelayMax
                       timeout:(NSUInteger)timeout {
    SocketConfig *config = [[SocketConfig alloc] init];
    config.path = path;
    config.reconnection = reconnection;
    config.reconnectionAttempts = reconnectionAttempts;
    config.reconnectionDelay = reconnectionDelay;
    config.reconnectionDelayMax = reconnectionDelayMax;
    config.timeout = timeout;
    return config;
}

- (NSDictionary *)configs {
    NSMutableDictionary *dict = [@{@"log": @NO,
                                  @"forcePolling": @YES,
                                  @"secure": @YES,
                                  @"reconnects" : @(_reconnection),
                                  @"reconnectAttempts" : @(_reconnectionAttempts),
                                  @"reconnectWait" :@4
                                  } mutableCopy];
    if (_path) {
        [dict setObject:_path forKey:@"path"];
    }
    return [dict copy];
}

@end

@implementation SocketClient

- (void)dealloc {
    _delegate = nil;
}

- (instancetype)initWithURL:(NSURL *)url
                     config:(SocketConfig *)config
                      queue:(dispatch_queue_t)queue
                   delegate:(id<SocketClientDelegate>)delegate {
    self = [super init];
    if (self) {
        _url = url;
        _config = config ?: [SocketConfig defaultConfig];
        _socketQueue = queue ?: dispatch_queue_create("com.ryan.socket.queue", NULL);
        _delegate = delegate;
    }
    return self;
}

- (void)connect {
    if (!_socket) {
        SocketIOClient *socket = [[SocketIOClient alloc] initWithSocketURL:_url config:_config.configs];
        _socket = socket;
        
        _status = SocketStatusConnecting;
        _isConnect = NO;

        [_socket connect];
        [self startListener];
        NSLog(@"start connect");
    }
}

- (void)disconnect {
    if (_status != SocketStatusNotConnected &&
        _status != SocketStatusDisConnected) {
        [_socket disconnect];
        _socket = nil;
        _status = SocketStatusDisConnected;
    }
}

- (void)send:(NSString *)event data:(NSArray *)data {
    [self emit:event items:data response:nil];
}

- (void)emit:(NSString *)event items:(NSArray *)items response:(void(^)(NSArray *datas))response {
    NSParameterAssert(event);
    if (!self.isConnect) return;
    
    NSArray *newItems = items ? @[items] : @[];
    
    if (response){
        OnAckCallback *callback = [self.socket emitWithAck:event with:newItems];
        [callback timingOutAfter:5 callback:^(NSArray * datas) {
            if (response) response(datas);
        }];
    }else{
        [self.socket emit:event with:newItems];
    }
}

- (void)onRecv:(NSString *)event calback:(void (^)(NSArray * _Nonnull))callback {
    [self on:event calback:callback];
}

- (void)on:(NSString *)event calback:(void (^)(NSArray *data))callback {
    [self.socket on:event callback:^(NSArray * _Nonnull data, SocketAckEmitter * _Nonnull ack) {
        if (callback) callback(data);
    }];
}

#pragma mark - privates

- (BOOL)respondsTo:(SEL)selector {
    if (self.delegate && [self.delegate respondsToSelector:selector]) {
        return YES;
    }
    return NO;
}

#pragma mark - startListener

- (void)startListener {
    //连接时触发
    [self on:@"connect" calback:^(NSArray *data) {
        NSLog(@"socket connect");
        _isConnect = YES;
        _status = SocketStatusConnected;
        [self recver];
        if ([self respondsTo:@selector(onConnection)]) {
            [self.delegate onConnection];
        }
    }];
    
    //连接时发生错误
    [self on:@"connect_error" calback:^(NSArray *data) {
        _isConnect = NO;
        _status = SocketStatusNotConnected;
    }];
    
    //连接时超时
    [self on:@"connect_timeout" calback:^(NSArray *data) {
        _isConnect = NO;
        _status = SocketStatusNotConnected;
    }];
    
    //断开连接时触发
    [self on:@"disconnect" calback:^(NSArray *data) {
        _isConnect = NO;
        _status = SocketStatusDisConnected;
        if ([self respondsTo:@selector(onDisconnect)]) {
            [self.delegate onDisconnect];
        }
    }];
    
    //成功重连后触发,num连接尝试次数
    [self on:@"reconnect" calback:^(NSArray *data) {
        
    }];
    
    //试图重新连接时触发
    [self on:@"reconnect_attempt" calback:^(NSArray *data) {
        
    }];
    
    //试图重新连接中触发,num连接尝试次数
    [self on:@"reconnecting" calback:^(NSArray *data) {
        if ([self respondsTo:@selector(onReconnecting)]) {
            [self.delegate onReconnecting];
        }
    }];
    
    //重联尝试错误,err
    [self on:@"reconnect_error" calback:^(NSArray *data) {
        _isConnect = NO;
        _status = SocketStatusNotConnected;
    }];
    
    //重连失败
    [self on:@"reconnect_failed" calback:^(NSArray *data) {
        _isConnect = NO;
        _status = SocketStatusNotConnected;
        if ([self respondsTo:@selector(onReconnectFailed)]) {
            [self.delegate onReconnectFailed];
        }
    }];
    
    //
    [self on:@"error" calback:^(NSArray *data) {
        NSLog(@"socket error");
        _isConnect = NO;
        _status = SocketStatusNotConnected;
        if ([self respondsTo:@selector(onSocketError)]) {
            [self.delegate onSocketError];
        }
    }];
}

@end
