//
//  CRPeer.h
//  Classroom3
//
//  Created by ryan on 2017/5/19.
//  Copyright © 2017年 ryan. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "CRUtilities.h"

@class RTCPeerConnection;
@class RTCPeerConnectionFactory;
@class CRCapturer;

@protocol CRPeerDelegate;

@interface CRPeer : NSObject <RTCPeerConnectionDelegate>

@property (nonatomic, weak) id<CRPeerDelegate> delegate;

@property (nonatomic, strong) NSArray *iceConfig;

@property (nonatomic, strong, readonly) RTCPeerConnection *peerConnection;
@property (nonatomic, weak, readonly) RTCPeerConnectionFactory *peerFactory;


- (instancetype)initWithDelegate:(id<CRPeerDelegate>)delegate peerFactory:(RTCPeerConnectionFactory *)peerFactory;

- (void)setMaxBitrateForPeerConnectionVideoSender;

- (void)muteLocalAudio:(BOOL)mute;

- (void)muteLocalVideo:(BOOL)mute;

- (void)destroy;

- (NSString *)stringForConnectionState:(RTCIceConnectionState)state;

@end

@protocol CRPeerDelegate <NSObject>

@optional

- (void)onAddLocalCapturer:(CRCapturer *)capturer;

- (void)onAddLocalVideoTrack:(RTCVideoTrack *)localVideotrack;

@required

- (void)onAddRemoteVideoTrack:(RTCVideoTrack *)remoteVideotrack peerId:(NSString *)peerId;

@end
