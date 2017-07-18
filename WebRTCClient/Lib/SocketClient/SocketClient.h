//
//  SocketClient.h
//  Classroom3
//
//  Created by ryan on 2017/4/24.
//  Copyright © 2017年 ryan. All rights reserved.
//

#import <Foundation/Foundation.h>
#import <SocketIO/SocketIO-Swift.h>

NS_ASSUME_NONNULL_BEGIN

typedef NS_ENUM(NSUInteger, SocketStatus) {
    SocketStatusNotConnected = 0,
    SocketStatusDisConnected = 1,
    SocketStatusConnecting = 2,
    SocketStatusConnected = 3
};

@protocol SocketClientDelegate;

@interface SocketConfig : NSObject

@property (nonatomic, copy, nullable) NSString *path;
//启动自动连接
@property (nonatomic, assign) BOOL reconnection;
//最大重试连接次数
@property (nonatomic, assign) NSUInteger reconnectionAttempts;
//最初尝试新的重新连接等待时间
@property (nonatomic, assign) NSUInteger reconnectionDelay;
//最大等待重新连接,之前的2倍增长
@property (nonatomic, assign) NSUInteger reconnectionDelayMax;
@property (nonatomic, assign) NSUInteger timeout;

+ (instancetype)defaultConfig;

+ (instancetype)configWithPath:(nullable NSString *)path
                  reconnection:(BOOL)reconnection
          reconnectionAttempts:(NSUInteger)reconnectionAttempts
             reconnectionDelay:(NSUInteger)reconnectionDelay
          reconnectionDelayMax:(NSUInteger)reconnectionDelayMax
                       timeout:(NSUInteger)timeout;

- (NSDictionary *)configs;

@end

@interface SocketClient : NSObject

@property (nonatomic, strong, readonly) NSURL *url;
@property (nonatomic, strong, readonly) SocketConfig *config;
@property (nonatomic, weak) id<SocketClientDelegate> delegate;
@property (nonatomic, strong, readonly) dispatch_queue_t socketQueue;

@property (nonatomic, assign, readonly) BOOL isConnect;
@property (nonatomic, assign, readonly) SocketStatus status;
@property (nonatomic, strong, readonly) SocketIOClient *socket;

- (instancetype)init NS_UNAVAILABLE;
+ (instancetype)new NS_UNAVAILABLE;

- (instancetype)initWithURL:(NSURL *)url
                     config:(nullable SocketConfig *)config
                      queue:(nullable dispatch_queue_t)queue
                   delegate:(id<SocketClientDelegate>)delegate NS_DESIGNATED_INITIALIZER;

- (void)connect;
- (void)disconnect;

- (void)send:(NSString *)event data:(nullable NSArray *)data;
- (void)onRecv:(NSString *)event calback:(void (^)(NSArray *data))callback;

@end

@protocol SocketClientDelegate <NSObject>

@optional

//socket
- (void)onConnection;

- (void)onDisconnect;

- (void)onSocketError;

- (void)onReconnectFailed;

- (void)onReconnecting;

//event
- (void)onRecv:(NSArray *)data;

//recver
- (void)onJoinSuccess:(NSArray *)data;

- (void)onLeave;

- (void)onKicked;
//重复登录,踢出原用户
- (void)onConfirmJoin;

- (void)onNewUser;

- (void)onOtherUserLeave:(NSArray *)data;

@end

NS_ASSUME_NONNULL_END
