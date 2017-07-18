//
//  CRMPeer.h
//  Classroom3
//
//  Created by ryan on 2017/4/24.
//  Copyright © 2017年 ryan. All rights reserved.
//

#import "CRPeer.h"

@interface CRMPeer : CRPeer

@property (nonatomic, copy) void(^sdpSender)(NSString *event, NSArray *datas) ;

- (void)createRTCPeer;

- (void)acceptRemoteOffer:(RTCSessionDescription *)desc;

@end
