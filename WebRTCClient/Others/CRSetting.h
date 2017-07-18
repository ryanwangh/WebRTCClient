//
//  CRSetting.h
//  Classroom3
//
//  Created by ryan on 2017/5/19.
//  Copyright © 2017年 ryan. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "CRTypes.h"

@interface CRSetting : NSObject

@property (nonatomic, assign, readonly) CGSize currentVideoResolution;

@property (nonatomic, copy, readonly) NSString *currentVideoCodec;

@property (nonatomic, strong) NSNumber *currentMaxBitrate;

+ (instancetype)settingWithResolution:(CRResolutionType)resolution codec:(CRCodecType)codec bitrate:(CRBitrateType)bitrate;

- (NSArray<NSString *> *)availableVideoResolutions;

- (NSArray<NSString *> *)availableVideoCodecs;

@end
