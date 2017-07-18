//
//  CRClient.m
//  Classroom3
//
//  Created by ryan on 2017/6/26.
//  Copyright © 2017年 ryan. All rights reserved.
//

#import "CRClient.h"
#import "SocketClient+Sender.h"
#import "CRRoom.h"
#import "CRStream.h"

@interface CRClient ()

@end

@implementation CRClient

- (instancetype)initWithRoom:(CRRoom *)room {
    if (self = [super init]) {
        _room = room;
        _recvOnly = NO;
        //_socketClient = [[SocketClient alloc] initWithURL:self.room.url config:nil queue:nil delegate:self];
    }
    return self;
}

- (void)setVideoCapturer:(UIView *)localVideo remoteRender:(UIView *)remoteVideo {
    _localVideo = localVideo;
    _remoteVideo = remoteVideo;
}

- (void)sendMsg:(NSArray *)data {
    [self.socketClient send:@"rtc" data:data];
}

- (void)changeKms:(NSString *)ip {
    [self sendMsg:@[@"changeKms", ip]];
}

- (void)start {
    [self.socketClient connect];
}

- (void)kickAndJoin {
    [self.socketClient kickAndJoin:self.room];
}

- (void)leave {
    [self.socketClient leave:self.room];
}

- (void)restart {
    [self leave];
    dispatch_after(dispatch_time(DISPATCH_TIME_NOW, (int64_t)(2 * NSEC_PER_SEC)), dispatch_get_main_queue(), ^{
        [self start];
    });
}

- (void)changeMediaServer:(NSString *)kmsIp {
    
}

- (void)changeRelayServer:(NSArray *)iceConfig {
    
}

- (void)switchCamera:(CRCameraType)cameraType {
    [self.localCapturer switchCamera:cameraType];
}

- (void)switchAudioRoute:(CRAudioType)audioType {
    [self.localCapturer switchAudioRoute:audioType];
}

- (void)destroy {
    
}

@end
