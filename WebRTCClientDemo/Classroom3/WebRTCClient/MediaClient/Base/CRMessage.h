//
//  CRMessage.h
//  Classroom3
//
//  Created by ryan on 2017/5/8.
//  Copyright © 2017年 ryan. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "CRTypes.h"

@class RTCSessionDescription;
@class RTCIceCandidate;

@interface CRMessage : NSObject

@property (nonatomic, assign, readonly) NSArray *source;

@property (nonatomic, assign, readonly) CRMessageActionType actionType;

@property (nonatomic, assign, readonly) CRMessageRoleType roleType;
@property (nonatomic, copy, readonly) NSString *targetUserId;

@property (nonatomic, strong, readonly) RTCSessionDescription *desc;
@property (nonatomic, strong, readonly) RTCIceCandidate *candidate;

- (instancetype)initWithData:(NSArray *)data;

@end
