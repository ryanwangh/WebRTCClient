//
//  CRMessage.m
//  Classroom3
//
//  Created by ryan on 2017/5/8.
//  Copyright © 2017年 ryan. All rights reserved.
//

#import "CRMessage.h"
#import <WebRTC/WebRTC.h>
#import "CRUtilities.h"
#import "CRSetting.h"

@implementation CRMessage

- (instancetype)initWithData:(NSArray *)data {
    self = [super init];
    if (self) {
        _source = data;
        NSString *action = GET_VALUE(data, 0);
        NSString *role = GET_VALUE(data, 1);
        NSString *userId = GET_VALUE(data, 2);
        id args = GET_VALUE(data, 3);
        
        if (!NullString(action)) {
            if ([action isEqualToString:@"send"]) {
                _actionType = CRMessageActionTypeSend;
            } else if ([action isEqualToString:@"recv"]) {
                _actionType = CRMessageActionTypeRecv;
            } else if ([action isEqualToString:@"stop"]) {
                _actionType = CRMessageActionTypeStop;
            } else if ([action isEqualToString:@"stopAll"]) {
                _actionType = CRMessageActionTypeStop;
            } else if ([action isEqualToString:@"reset"]) {
                _actionType = CRMessageActionTypeStop;
            } else if ([action isEqualToString:@"sdpAnswer"]) {
                _actionType = CRMessageActionTypeAnswer;
            } else if ([action isEqualToString:@"iceCandidate"]) {
                _actionType = CRMessageActionTypeCandidate;
            }
        }
        
        if (!NullString(role)) {
            if ([role isEqualToString:@"sender"]) {
                _roleType = CRMessageRoleTypeSender;
            } else if ([role isEqualToString:@"recver"]) {
                _roleType = CRMessageRoleTypeRecver;
            }
        }
        
        _targetUserId = userId;
        
        if ([args isKindOfClass:[NSDictionary class]]) {
            _candidate = [RTCIceCandidate candicdateWithInfo:args];
        } else if ([args isKindOfClass:[NSString class]]) {
            CRSetting *setting = [[CRSetting alloc] init];
            _desc = [[RTCSessionDescription alloc] initWithType:RTCSdpTypeAnswer sdp:args];
            _desc = [RTCSessionDescription updateCodecForDescription:_desc preferredVideoCodec:setting.currentVideoCodec];
        }
        
    }
    return self;
}

@end
