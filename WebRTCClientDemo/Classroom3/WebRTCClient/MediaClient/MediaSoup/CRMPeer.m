//
//  CRMPeer.m
//  Classroom3
//
//  Created by ryan on 2017/4/24.
//  Copyright © 2017年 ryan. All rights reserved.
//

#import "CRMPeer.h"
#import "CRStream.h"
#import "CRSetting.h"

@implementation CRMPeer

@synthesize peerConnection = _peerConnection;

- (void)createRTCPeer {
    RTCMediaConstraints *constraints = [RTCMediaConstraints connectionConstraints];
    
    RTCConfiguration *config = [[RTCConfiguration alloc] init];
    [config setIceServers: self.iceConfig];
    
    RTCPeerConnection *connection = [self.peerFactory peerConnectionWithConfiguration:config constraints:constraints delegate:self];
    _peerConnection = connection;
    
    [[CRStream streamWithPeer:self] getUserMedia:^(CRCapturer *capturer) {
        [self.delegate onAddLocalCapturer:capturer];
    }];
    
    @weakify(self);
    [self.peerConnection offerForConstraints:[RTCMediaConstraints offerConstraints:YES] completionHandler:^(RTCSessionDescription * _Nullable sdp, NSError * _Nullable error) {
        if (error) RTCLogError(@"%@",error);
        @strongify(self);
        [self sdpSender:@"offer" datas:@[@"desc", sdp.info]];
    }];
}

- (void)sdpSender: (NSString *)event datas:(NSArray *)datas {
    if (self.sdpSender) self.sdpSender(event, datas);
}

- (void)acceptRemoteOffer:(RTCSessionDescription *)desc {
    NSLog(@"acceptRemoteOffer");
    @weakify(self)
    [self.peerConnection setRemoteDescription:desc completionHandler:^(NSError * _Nullable error) {
        if (error) RTCLogError(@"%@",error);
        @strongify(self)
        [self createAnswer];
    }];
}

- (void)createAnswer {
    @weakify(self)
    [self.peerConnection answerForConstraints:[RTCMediaConstraints answerConstraints] completionHandler:^(RTCSessionDescription * _Nullable sdp, NSError * _Nullable error) {
        if (error) RTCLogError(@"%@",error);
        @strongify(self);
        [self onCreateAnswerSuccess:sdp];
    }];
}

- (void)onCreateAnswerSuccess:(RTCSessionDescription *)desc {
    @weakify(self);
    CRSetting *setting = [[CRSetting alloc] init];
    desc = [RTCSessionDescription updateCodecForDescription:desc preferredVideoCodec:setting.currentVideoCodec];
    //desc = [RTCSessionDescription updateBandwidthRestriction:desc bandwidth:80];
    [self.peerConnection setLocalDescription:desc completionHandler:^(NSError * _Nullable error) {
        if (error) RTCLogError(@"%@",error);
        @strongify(self);
        [self sdpSender:@"answer" datas:@[@"desc", desc.info]];
    }];
}

@end
