//
//  KurentoClient.m
//  Classroom3
//
//  Created by ryan on 2017/5/5.
//  Copyright © 2017年 ryan. All rights reserved.
//

#import "KurentoClient.h"
#import "SocketClient+Sender.h"
#import "CRKPeer.h"
#import "CRStream.h"
#import "CRRoom.h"
#import "CRMessage.h"

@interface KurentoClient () <SocketClientDelegate, CRPeerDelegate>

//peer
@property (nonatomic, copy, readonly) NSString *uid;

@property (nonatomic, strong) RTCPeerConnectionFactory *peerFactory;
@property (nonatomic, strong, readonly) CRKPeer *senderPeer;
@property (nonatomic, strong, readonly) NSMutableDictionary<NSString*, CRKPeer *> *recverPeers;

//render
@property (nonatomic, strong, readonly) CRRenderer *localRender;
@property (nonatomic, strong, readonly) NSMutableDictionary<NSString*, CRRenderer *> *remoteRenders;

//other
@property (nonatomic, strong) dispatch_queue_t webrtcQueue;

@end

@implementation KurentoClient

@synthesize socketClient = _socketClient;
@synthesize localCapturer = _localCapturer;
@synthesize iceConfig = _iceConfig;

- (instancetype)initWithRoom:(CRRoom *)room {
    if (self = [super initWithRoom:room]) {
        _webrtcQueue = dispatch_queue_create("com.ryan.kurento.queue", NULL);
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
    _recverPeers = [NSMutableDictionary dictionaryWithCapacity:2];
    _remoteRenders = [NSMutableDictionary dictionaryWithCapacity:2];
    
    _socketClient = [[SocketClient alloc] initWithURL:self.room.url config:nil queue:nil delegate:self];
}

- (void)muteLocalAudio:(BOOL)mute {
    [self.senderPeer muteLocalAudio:mute];
}

- (void)muteLocalVideo:(BOOL)mute {
    [self.senderPeer muteLocalVideo:mute];
}

- (void)destroy {
    [self.socketClient disconnect];
    [self stopAll];
}

#pragma mark - privates

- (void)join {
    [self.socketClient tryJoin:self.room];
}

- (void)createSender {
    NSString *peeId = self.uid;
    BOOL isSender = YES;
    BOOL isAsAnswer = NO;
    
    _senderPeer = [self createPeer:peeId isSender:isSender isAnswer:isAsAnswer];
    [RTCDispatcher dispatchAsyncOnType:RTCDispatcherTypeCaptureSession block:^{
        [[CRStream streamWithPeer:_senderPeer] getUserMedia:^(CRCapturer *capturer) {
            [self addLocalCapturer:capturer];
            [self.senderPeer generateOffer];
        }];
    }];
}

- (CRKPeer *)createRecver:(NSString *)senderId {
    NSString *peeId = senderId;
    BOOL isSender = NO;
    BOOL isAsAnswer = NO;
    CRKPeer *peer = [self createPeer:peeId isSender:isSender isAnswer:isAsAnswer];
    [self.recverPeers setObject:peer forKey:peeId];
    [peer generateOffer];
    return nil;
}

- (CRKPeer *)createPeer:(NSString *)uid isSender:(BOOL)isSender isAnswer:(BOOL)isAnswer {
    CRKPeer *peer = [[CRKPeer alloc] initWithId:uid isSender:isSender isAnswer:isAnswer iceConfig:nil peerFactory:self.peerFactory delegate:self];
    @weakify(self)
    peer.onDescription = ^(RTCSessionDescription *desc) {
        NSString *action = isSender ? @"send" : @"recv";
        NSLog(@"=====socket sdp action:%@",action);
        @strongify(self)
        [self sendMsg:@[action, desc.sdp, uid]];
    };
    peer.onIceCandidate = ^(RTCIceCandidate *candidate) {
        NSString *action = isSender ? @"sender" : @"recver";
        NSLog(@"=====socket iceCandidate action:%@",action);
        @strongify(self)
        [self sendMsg:@[@"iceCandidate", action, uid, candidate.info]];
    };
    return peer;
}

- (void)updateStream {
    if (self.senderPeer) {
        [self restartSend];
    }
}

- (void)updateIce:(NSArray *)iceConfig {
    _iceConfig = iceConfig;
    [self restartAll];
}

- (void)sdpUpdate {
    [self sendMsg:@[@"sdpUpdate"]];
}

- (void)stopAll {
    [self closeSender];
    [self closeRecvers];
}

- (void)stopAllThenSend {
    BOOL recvOnly = !self.senderPeer;
    [self stopAll];
    if (recvOnly) {
        return;
    }
    [self createSender];
}

- (void)closeSender {
    [self.localRender remove];
    [self.senderPeer destroy];
}

- (void)closeRecvers {
    [[self.recverPeers.allValues copy] enumerateObjectsUsingBlock:^(CRKPeer * _Nonnull peer, NSUInteger idx, BOOL * _Nonnull stop) {
        [self disposePeer:peer];
    }];
    [self.recverPeers removeAllObjects];
    [self.remoteRenders removeAllObjects];
}

- (void)disposePeer:(CRKPeer *)peer {
    CRRenderer *render = self.remoteRenders[peer.uid];
    [render remove];
    [self.remoteRenders removeObjectForKey:peer.uid];
    
    [peer destroy];
    [self.recverPeers removeObjectForKey:peer.uid];
}

- (CRKPeer *)getPeer:(CRMessageRoleType)roleType uId:(NSString *)userId {
    switch (roleType) {
        case CRMessageRoleTypeSender:
            return self.senderPeer;
            break;
        case CRMessageRoleTypeRecver:
            return self.recverPeers[userId];
            break;
        default:
            break;
    }
    return nil;
}

- (void)restartAll {
    [self stopAll];
    [self sendMsg:@[@"restartAll"]];
}

- (void)restartSend {
    [self removePeer:CRMessageRoleTypeSender uId:self.uid];
    [self sendMsg:@[@"restartSend"]];
}

- (void)restartRecv:(NSString *)uid {
    [self removePeer:CRMessageRoleTypeRecver uId:uid];
    [self sendMsg:@[@"restartRecv", uid]];
}

- (void)removePeer:(CRMessageRoleType)roleType uId:(NSString *)userId {
    CRKPeer *peer = [self getPeer:roleType uId:userId];
    if (!peer) return;
    [self disposePeer:peer];
}

- (void)addLocalCapturer:(CRCapturer *)capturer {
    _localCapturer = capturer;

    [RTCDispatcher dispatchAsyncOnType:RTCDispatcherTypeMain block:^{
        CRRenderer *render = [CRRenderer rendererForCapturer:capturer frame:self.localVideo.bounds];
        _localRender = render;
        [self.localVideo addSubview:render];
    }];
    
    [capturer startCapture];
}

- (void)addRemoteRender:(RTCVideoTrack *)track peerId:(NSString *)peerId {
    CRRenderer *render = [CRRenderer rendererForTrack:track frame:self.remoteVideo.bounds];
    if (peerId) [_remoteRenders setObject:render forKey:peerId];
    [self.remoteVideo addSubview: render];
}

#pragma mark - CRPeerDelegate

- (void)onAddRemoteVideoTrack:(RTCVideoTrack *)remoteVideotrack peerId:(NSString *)peerId {
    [self addRemoteRender:remoteVideotrack peerId:peerId];
}

#pragma mark - SocketClientDelegate

//socket
- (void)onConnection {
    [self join];
}

- (void)onDisconnect {
    [self stopAll];
}

- (void)onRecv:(NSArray *)data {
    CRMessage *message = [[CRMessage alloc] initWithData:data];
    switch (message.actionType) {
        case CRMessageActionTypeSend:
            [self createSender];
            break;
        case CRMessageActionTypeRecv:
            if ([message.targetUserId isEqualToString:self.uid]) return;
            [self createRecver:message.targetUserId];
            break;
        case CRMessageActionTypeStop:
            [self removePeer:message.roleType uId:message.targetUserId];
            break;
        case CRMessageActionTypeStopAll:
            [self stopAll];
            break;
        case CRMessageActionTypeReset:
            [self stopAllThenSend];
            break;
        case CRMessageActionTypeAnswer:
            NSLog(@"%@ %@ setRemoteDescription",message.roleType == CRMessageRoleTypeSender ? @"sender" : @"recverPeers",message.targetUserId);
            [[self getPeer:message.roleType uId:message.targetUserId] applyRemoteDescription:message.desc];
            break;
        case CRMessageActionTypeCandidate:
            [[self getPeer:message.roleType uId:message.targetUserId] addIce:message.candidate];
            break;
        default:
            break;
    }
}

//recv
- (void)onJoinSuccess:(NSArray *)data {
    if (self.recvOnly) return;
    if (data && data.count && [data[0] isKindOfClass:[NSString class]]) {
        _uid = data[0];
        [self createSender];
    }
}

- (void)onLeave {
    [self stopAll];
}

- (void)onKicked {
    
}

- (void)onConfirmJoin {
    [self kickAndJoin];
}

- (void)onNewUser {
    
}

- (void)onOtherUserLeave:(NSArray *)data {
    if (data && data.count && [data[0] isKindOfClass:[NSArray class]] && [(NSArray *)data[0] count]) {
        NSString *uid = data[0][0];
        [self removePeer:CRMessageRoleTypeRecver uId:uid];
    }
}

@end
