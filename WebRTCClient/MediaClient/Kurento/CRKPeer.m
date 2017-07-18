//
//  CRKPeer.m
//  Classroom3
//
//  Created by ryan on 2017/5/5.
//  Copyright © 2017年 ryan. All rights reserved.
//

#import "CRKPeer.h"
#import "CRMessage.h"
#import "CRSetting.h"

@interface CRKPeer ()

@property (nonatomic, copy, readonly) NSString *role;
@property (nonatomic, assign, readonly) BOOL isSender;
@property (nonatomic, assign, readonly) BOOL isAnswer;

@property (nonatomic, assign, readonly) BOOL isTimeToAddIceCandidate;
@property (nonatomic, strong) NSMutableArray<RTCIceCandidate *> *candidatesQueue;

@end

@implementation CRKPeer

@synthesize iceConfig = _iceConfig;
@synthesize peerConnection = _peerConnection;
@synthesize peerFactory = _peerFactory;
@synthesize delegate = _delegate;

- (instancetype)initWithId:(NSString *)uid isSender:(BOOL)isSender isAnswer:(BOOL)isAnswer iceConfig:(NSArray *)iceConfig peerFactory:(RTCPeerConnectionFactory *)peerFactory delegate:(id<CRPeerDelegate>)delegate {
    self = [super init];
    if (self) {
        _uid = uid;
        _isSender = isSender;
        _isAnswer = isAnswer;
        _iceConfig = iceConfig;
        _peerFactory = peerFactory;
        _delegate = delegate;
        _role = _isAnswer ? @"asAnswer" : @"asOffer";
        _candidatesQueue = [NSMutableArray arrayWithCapacity:10];
        [self commonInit];
    }
    return self;
}

- (void)commonInit {
    RTCMediaConstraints *constraints = [RTCMediaConstraints connectionConstraints];
    
    RTCConfiguration *config = [[RTCConfiguration alloc] init];
    [config setIceServers: self.iceConfig];
    
    RTCPeerConnection *connection = [self.peerFactory peerConnectionWithConfiguration:config constraints:constraints delegate:self];
    _peerConnection = connection;
}

- (BOOL)isTimeToAddIceCandidate {
    return self.peerConnection && self.peerConnection.signalingState == RTCSignalingStateStable;
}

- (void)addIce:(RTCIceCandidate *)candidate {
    if (!self.isTimeToAddIceCandidate) {
        [_candidatesQueue addObject:candidate];
        return;
    }
    [self.peerConnection addIceCandidate:candidate];
}

- (void)addIceQueue {
    for (RTCIceCandidate *candidate in self.candidatesQueue) {
        [self addIce:candidate];
    }
}

- (void)applyRemoteDescription:(RTCSessionDescription *)desc {
    @weakify(self);
    [self.peerConnection setRemoteDescription:desc completionHandler:^(NSError * _Nullable error) {
        if (error) RTCLogError(@"%@",error);
        @strongify(self)
        [self addIceQueue];
        if ([self.role isEqualToString:@"asOffer"]) return ;
        [self.peerConnection answerForConstraints:[RTCMediaConstraints answerConstraints] completionHandler:^(RTCSessionDescription * _Nullable sdp, NSError * _Nullable error) {
            if (error) RTCLogError(@"%@",error);
            @strongify(self)
            NSLog(@"answerForConstraints");
            CRSetting *setting = [[CRSetting alloc] init];
            RTCSessionDescription *sdpCodec = [RTCSessionDescription updateCodecForDescription:sdp preferredVideoCodec:setting.currentVideoCodec];
            [self.peerConnection setLocalDescription:sdpCodec completionHandler:^(NSError * _Nullable error) {
                if (error) RTCLogError(@"%@",error);
                @strongify(self)
                NSLog(@"setLocalDescription");
                if (self.onDescription) self.onDescription(sdp);
            }];
            [self setMaxBitrateForPeerConnectionVideoSender];
        }];
    }];
}

- (void)generateOffer {
    NSLog(@"generateOffer %@",self.uid);
    @weakify(self);
    [self.peerConnection offerForConstraints:[RTCMediaConstraints offerConstraints:self.isSender] completionHandler:^(RTCSessionDescription * _Nullable sdp, NSError * _Nullable error) {
        if (error) RTCLogError(@"%@",error);
        @strongify(self);
        if ([self.role isEqualToString:@"asOffer"]) {
            CRSetting *setting = [[CRSetting alloc] init];
            RTCSessionDescription *sdpCodec = [RTCSessionDescription updateCodecForDescription:sdp preferredVideoCodec:setting.currentVideoCodec];
            [self.peerConnection setLocalDescription:sdpCodec completionHandler:^(NSError * _Nullable error) {
                if (error) RTCLogError(@"%@",error);
                @strongify(self)
                NSLog(@"setLocalDescription");
                if (self.onDescription) self.onDescription(sdp);
            }];
            [self setMaxBitrateForPeerConnectionVideoSender];
        }
        return ;
    }];
}

#pragma mark - RTCPeerConnectionDelegate

-(void)peerConnection:(RTCPeerConnection *)peerConnection didAddStream:(RTCMediaStream *)stream {
    if (self.isSender || !stream.videoTracks || !stream.videoTracks.count) return;
    [RTCDispatcher dispatchAsyncOnType:RTCDispatcherTypeMain block:^{
        NSLog(@"received remote stream");
        [self.delegate onAddRemoteVideoTrack:stream.videoTracks[0] peerId:self.uid];
    }];
}

- (void)peerConnection:(RTCPeerConnection *)peerConnection didGenerateIceCandidate:(RTCIceCandidate *)candidate {
    if (self.onIceCandidate) self.onIceCandidate(candidate);
}

-(void)peerConnection:(RTCPeerConnection *)peerConnection didChangeIceConnectionState:(RTCIceConnectionState)newState {
    NSLog(@"Peer connection - %@ - ICE state changed: %@", self.uid,[self stringForConnectionState:newState]);
}

@end
