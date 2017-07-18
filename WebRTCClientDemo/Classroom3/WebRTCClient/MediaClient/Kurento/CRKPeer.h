//
//  CRKPeer.h
//  Classroom3
//
//  Created by ryan on 2017/5/5.
//  Copyright © 2017年 ryan. All rights reserved.
//

#import "CRPeer.h"

@interface CRKPeer : CRPeer

@property (nonatomic, copy, readonly) NSString *uid;

@property (nonatomic, copy) void(^onDescription)(RTCSessionDescription *desc) ;
@property (nonatomic, copy) void(^onIceCandidate)(RTCIceCandidate *candidate) ;

- (instancetype)initWithId:(NSString *)uid isSender:(BOOL)isSender isAnswer:(BOOL)isAnswer iceConfig:(NSArray *)iceConfig peerFactory:(RTCPeerConnectionFactory *)peerFactory delegate:(id<CRPeerDelegate>)delegate;

- (void)addIce:(RTCIceCandidate *)candidate;

- (void)applyRemoteDescription:(RTCSessionDescription *)desc;

- (void)generateOffer;

@end
