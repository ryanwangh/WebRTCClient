//
//  CRPeer.m
//  Classroom3
//
//  Created by ryan on 2017/5/19.
//  Copyright © 2017年 ryan. All rights reserved.
//

#import "CRPeer.h"
#import <WebRTC/WebRTC.h>
#import "CRSetting.h"

@implementation CRPeer

- (instancetype)initWithDelegate:(id<CRPeerDelegate>)delegate peerFactory:(RTCPeerConnectionFactory *)peerFactory {
    self = [super init];
    if (self) {
        _delegate = delegate;
        _peerFactory = peerFactory;
    }
    return self;
}

- (void)setMaxBitrateForPeerConnectionVideoSender {
    for (RTCRtpSender *sender in self.peerConnection.senders) {
        if (sender.track != nil) {
            if ([sender.track.kind isEqualToString:@"video"]) {
                CRSetting *setting = [[CRSetting alloc] init];
                NSNumber *maxBitrate = setting.currentMaxBitrate;
                if (maxBitrate.intValue <= 0) return;
                
                RTCRtpParameters *parametersToModify = sender.parameters;
                for (RTCRtpEncodingParameters *encoding in parametersToModify.encodings) {
                    encoding.maxBitrateBps = @(maxBitrate.intValue * 1000);
                }
                [sender setParameters:parametersToModify];
            }
        }
    }
}

- (void)muteLocalAudio:(BOOL)mute {
    for (RTCRtpSender *sender in self.peerConnection.senders) {
        if (sender.track != nil) {
            if ([sender.track.kind isEqualToString:@"audio"]) {
                sender.track.isEnabled = !mute;
            }
        }
    }
}

- (void)muteLocalVideo:(BOOL)mute {
    for (RTCRtpSender *sender in self.peerConnection.senders) {
        if (sender.track != nil) {
            if ([sender.track.kind isEqualToString:@"video"]) {
                sender.track.isEnabled = !mute;
            }
        }
    }
}

- (void)destroy {
#if defined(WEBRTC_IOS)
    [_factory stopAecDump];
    [_peerConnection stopRtcEventLog];
#endif
    [_peerConnection close];
    _peerConnection = nil;
}

- (NSString *)stringForConnectionState:(RTCIceConnectionState)state{
    switch (state) {
        case RTCIceConnectionStateNew:
            return @"New";
            break;
        case RTCIceConnectionStateChecking:
            return @"Checking";
            break;
        case RTCIceConnectionStateConnected:
            return @"Connected";
            break;
        case RTCIceConnectionStateCompleted:
            return @"Completed";
            break;
        case RTCIceConnectionStateFailed:
            return @"Failed";
            break;
        case RTCIceConnectionStateDisconnected:
            return @"Disconnected";
            break;
        case RTCIceConnectionStateClosed:
            return @"Closed";
            break;
        default:
            return @"Other state";
            break;
    }
}

#pragma mark - RTCSessionDescriptionDelegate

- (void)peerConnection:(RTCPeerConnection *)peerConnection didCreateSessionDescription:(RTCSessionDescription *)sdp error:(NSError *)error{}

- (void)peerConnection:(RTCPeerConnection *)peerConnection didSetSessionDescriptionWithError:(NSError *)error {}

#pragma mark - RTCPeerConnectionDelegate

- (void)peerConnection:(RTCPeerConnection *)peerConnection didChangeSignalingState:(RTCSignalingState)stateChanged {}

-(void)peerConnection:(RTCPeerConnection *)peerConnection didAddStream:(RTCMediaStream *)stream {
    if (!stream.videoTracks || !stream.videoTracks.count) return;
    [RTCDispatcher dispatchAsyncOnType:RTCDispatcherTypeMain block:^{
        NSLog(@"received remote stream");
        [self.delegate onAddRemoteVideoTrack:stream.videoTracks[0] peerId:nil];
    }];
}

-(void)peerConnection:(RTCPeerConnection *)peerConnection didRemoveStream:(RTCMediaStream *)stream {}

-(void)peerConnectionShouldNegotiate:(RTCPeerConnection *)peerConnection {}

-(void)peerConnection:(RTCPeerConnection *)peerConnection didChangeIceConnectionState:(RTCIceConnectionState)newState {
    NSLog(@"Peer connection - ICE state changed: %@", [self stringForConnectionState:newState]);
}

-(void)peerConnection:(RTCPeerConnection *)peerConnection didChangeIceGatheringState:(RTCIceGatheringState)newState {}

- (void)peerConnection:(RTCPeerConnection *)peerConnection didGenerateIceCandidate:(RTCIceCandidate *)candidate {}

- (void)peerConnection:(RTCPeerConnection *)peerConnection didRemoveIceCandidates:(NSArray<RTCIceCandidate *> *)candidates {}

- (void)peerConnection:(RTCPeerConnection *)peerConnection didOpenDataChannel:(RTCDataChannel *)dataChannel {}

@end
