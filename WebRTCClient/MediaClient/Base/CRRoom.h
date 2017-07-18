//
//  CRRoom.h
//  Classroom3
//
//  Created by ryan on 2017/4/25.
//  Copyright © 2017年 ryan. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "CRTypes.h"

@interface CRRoom : NSObject

@property (nonatomic, strong, readonly) NSURL *url;
@property (nonatomic, copy, readonly) NSString *roomId;
@property (nonatomic, copy, readonly) NSString *userId;
@property (nonatomic, assign, readonly) CRUserType userType;
@property (nonatomic, strong, readonly) NSDictionary *userInfo;

- (instancetype)init NS_UNAVAILABLE;
+ (instancetype)new NS_UNAVAILABLE;

- (instancetype)initWithUrl:(NSURL *)url
                     userId:(NSString *)userId
                     roomId:(NSString *)roomId
                   userType:(CRUserType)userType
                   userInfo:(NSDictionary *)userInfo;

- (NSArray *)items;
@end
