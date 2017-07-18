//
//  CRRoom.m
//  Classroom3
//
//  Created by ryan on 2017/4/25.
//  Copyright © 2017年 ryan. All rights reserved.
//

#import "CRRoom.h"

@implementation CRRoom

- (instancetype)initWithUrl:(NSURL *)url
                     userId:(NSString *)userId
                     roomId:(NSString *)roomId
                   userType:(CRUserType)userType
                   userInfo:(NSDictionary *)userInfo {
    NSParameterAssert(url);
    NSParameterAssert(userId);
    NSParameterAssert(roomId);
    NSParameterAssert(userType);
    
    self = [super init];
    if (self) {
        _url = url;
        _userId = userId;
        _roomId = roomId;
        _userType = userType;
        _userInfo = userInfo;
    }
    return self;
}

- (NSArray *)items {
    NSMutableArray *array = [@[self.roomId, self.userId, @(self.userType)] mutableCopy];
    if (!NullDictionary(self.userInfo)) [array addObject:self.userInfo];
    return [array copy];
}

- (NSString *)description {
    return [NSString stringWithFormat:@"[%@: roomId: %@ userId: %@]", NSStringFromClass([self class]), self.roomId, self.userId];
}

@end
