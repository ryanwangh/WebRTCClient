//
//  CRUtilities.h
//  Classroom3
//
//  Created by ryan on 2017/5/8.
//  Copyright © 2017年 ryan. All rights reserved.
//

#import <Foundation/Foundation.h>
#import <WebRTC/WebRTC.h>

@class RTCMediaConstraints;

@interface RTCMediaConstraints (constraints)

+ (RTCMediaConstraints *)connectionConstraints;

+ (RTCMediaConstraints *)offerConstraints:(BOOL)isSender;

+ (RTCMediaConstraints *)answerConstraints;

+ (RTCMediaConstraints *)audioConstraints;

+ (RTCMediaConstraints *)videoConstraints;

@end

@interface RTCSessionDescription (sdp)

+ (RTCSessionDescription *)updateBandwidthRestriction:(RTCSessionDescription *)sessionDescription bandwidth:(NSUInteger)bandwidth;

// Updates the original SDP description to instead prefer the specified video
// codec. We do this by placing the specified codec at the beginning of the
// codec list if it exists in the sdp.
+ (RTCSessionDescription *)updateCodecForDescription:(RTCSessionDescription *)description preferredVideoCodec:(NSString *)codec;

//json dict
+ (RTCSessionDescription *)sdpWithInfo:(NSDictionary *)info;

- (NSDictionary *)info;

@end

@interface RTCIceCandidate (candidate)

+ (RTCIceCandidate *)candicdateWithInfo:(NSDictionary *)info;

- (NSDictionary *)info;

@end

@interface CRUtilities : NSObject

- (NSDictionary *)getDevices;

@end

