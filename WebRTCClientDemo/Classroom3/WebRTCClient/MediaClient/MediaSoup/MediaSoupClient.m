//
//  MediaSoupClient.m
//  Classroom3
//
//  Created by ryan on 2017/4/25.
//  Copyright © 2017年 ryan. All rights reserved.
//

#import "MediaSoupClient.h"
#import "SocketClient+Sender.h"
#import "CRMPeer.h"
#import "CRRoom.h"
#import "CRStream.h"

@interface MediaSoupClient () <SocketClientDelegate, CRPeerDelegate>

//peer
@property (nonatomic, strong, readonly) CRMPeer *peer;
@property (nonatomic, strong) RTCPeerConnectionFactory *peerFactory;

//render
@property (nonatomic, strong, readonly) CRRenderer *localRender;
@property (nonatomic, strong, readonly) NSMutableArray<CRRenderer *> *remoteRenders;

@end

@implementation MediaSoupClient

@synthesize socketClient = _socketClient;
@synthesize localCapturer = _localCapturer;
@synthesize iceConfig = _iceConfig;

- (instancetype)initWithRoom:(CRRoom *)room {
    self = [super initWithRoom:room];
    if (self) {
        [self commonInit];
    }
    return self;
}

- (RTCPeerConnectionFactory *)peerFactory {
    if (!_peerFactory) {
        _peerFactory = [[RTCPeerConnectionFactory alloc] init];
    }
    return _peerFactory;
}

- (void)commonInit {
    _iceConfig = [NSArray array];
    _socketClient = [[SocketClient alloc] initWithURL:self.room.url config:nil queue:nil delegate:self];
}

- (void)changeMediaServer:(NSString *)kmsIp {
    [self changeKms:kmsIp];
}

- (void)changeRelayServer:(NSArray *)iceConfig {
    [self updateIce:iceConfig];
}

- (void)destroy {
    [self.socketClient disconnect];
    [self closePeer];
}

#pragma mark - privates

- (CRMPeer *)createPeer {
    CRMPeer *peer = [[CRMPeer alloc] initWithDelegate:self peerFactory:self.peerFactory];
    peer.iceConfig = self.iceConfig;
    @weakify(self)
    peer.sdpSender = ^(NSString *event, NSArray *datas) {
        @strongify(self)
        [self sendMsg:datas];
    };
    [peer createRTCPeer];
    _peer = peer;
    return peer;
}

- (void)closePeer {
    [self.peer destroy];
    [self.localRender remove];
    for (CRRenderer *render in self.remoteRenders) {
        [render remove];
    }
    [self.remoteRenders removeAllObjects];
}

- (void)updateIce:(NSArray *)iceConfig {
    _iceConfig = iceConfig;
}

- (void)sdpUpdate {
    [self sendMsg:@[@"sdpUpdate"]];
}

- (void)stopAll {
    [self closePeer];
}

- (void)stopAllThenSend {
    BOOL recvOnly = !self.peer;
    [self stopAll];
    if (recvOnly) {
        return;
    }
    [self createPeer];
}

- (void)restartAll {
    [self sdpUpdate];
}

- (void)restartSend {
    [self sdpUpdate];
}

- (void)restartRecv {
    [self sdpUpdate];
}

#pragma mark - CRMPeerDelegate

- (void)onAddLocalCapturer:(CRCapturer *)capturer {
    _localCapturer = capturer;
    
    [RTCDispatcher dispatchAsyncOnType:RTCDispatcherTypeMain block:^{
        CRRenderer *render = [CRRenderer rendererForCapturer:capturer frame:self.localVideo.bounds];
        _localRender = render;
        [self.localVideo addSubview:render];
    }];
    
    [capturer startCapture];
}

- (void)onAddRemoteVideoTrack:(RTCVideoTrack *)remoteVideotrack peerId:(NSString *)peerId {
    [RTCDispatcher dispatchAsyncOnType:RTCDispatcherTypeMain block:^{
        CRRenderer *render = [CRRenderer rendererForTrack:remoteVideotrack frame:self.remoteVideo.bounds];
        [_remoteRenders addObject:render];
        [self.remoteVideo addSubview: render];
    }];
}

#pragma mark - SocketClientDelegate

//socket
- (void)onConnection {
    [self.socketClient tryJoin:self.room];
}

- (void)onDisconnect {
    [self closePeer];
}

- (void)onRecv:(NSArray *)data {
    NSString *action = [data objectAtIndex:0];
    if ([action isEqualToString:@"sdp"]) {
        NSDictionary *info = [data objectAtIndex:1][@"offer"];
        RTCSessionDescription *sessionDescription = [RTCSessionDescription sdpWithInfo:info];
        [self.peer acceptRemoteOffer:sessionDescription];
    }
}

//recv
- (void)onJoinSuccess:(NSArray *)data {
    [self createPeer];
}

- (void)onLeave {
    [self closePeer];
}

- (void)onKicked {
    
}

- (void)onConfirmJoin {
    [self.socketClient kickAndJoin:self.room];
}

@end
