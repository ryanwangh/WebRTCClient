//
//  CRClient.h
//  Classroom3
//
//  Created by ryan on 2017/6/26.
//  Copyright © 2017年 ryan. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "CRTypes.h"

@class SocketClient;
@class CRRoom;
@class CRCapturer;

@protocol CRClientDelegate <NSObject>

- (void)setVideoCapturer:(UIView *)localVideo remoteRender:(UIView *)remoteVideo;

- (void)start;

- (void)kickAndJoin;

- (void)leave;

- (void)restart;

- (void)changeMediaServer:(NSString *)kmsIp;

- (void)changeRelayServer:(NSString *)iceConfig;

- (void)switchCamera:(CRCameraType)cameraType;

- (void)switchAudioRoute:(CRAudioType)audioType;

- (void)destroy;

@end

@interface CRClient : NSObject <CRClientDelegate>

@property (nonatomic, strong, readonly) CRRoom *room;

@property (nonatomic, strong, readonly) SocketClient *socketClient;

@property (nonatomic, strong, readonly) CRCapturer *localCapturer;
@property (nonatomic, strong, readonly) UIView *remoteVideo;
@property (nonatomic, strong, readonly) UIView *localVideo;

@property (nonatomic, strong, readonly) NSArray *iceConfig;
@property (nonatomic, assign, getter=isRecvOnly) BOOL recvOnly;


- (instancetype)initWithRoom:(CRRoom *)room;

//

- (void)start;

- (void)kickAndJoin;

- (void)leave;

- (void)restart;

- (void)changeMediaServer:(NSString *)kmsIp;

- (void)changeRelayServer:(NSArray *)iceConfig;

- (void)switchCamera:(CRCameraType)cameraType;

- (void)switchAudioRoute:(CRAudioType)audioType;

- (void)destroy;

//

- (void)sendMsg:(NSArray *)data;

- (void)changeKms:(NSString *)ip;

@end

