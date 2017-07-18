//
//  ClassRoomManager.h
//  Classroom3
//
//  Created by ryan on 2017/5/25.
//  Copyright © 2017年 ryan. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "CRRoom.h"

typedef NS_ENUM(NSUInteger, ClassRoomType) {
    ClassRoomTypeKurento = 1,
    ClassRoomTypeMediaSoup = 2,
    ClassRoomTypeAgora = 3
};

@interface ClassRoomManager : NSObject

+ (void)setup;

+ (void)clear;

- (void)setVideoCapturer:(UIView *)localVideo remoteRender:(UIView *)remoteVideo;

- (void)setResolution:(CRResolutionType)resolution codec:(CRCodecType)codec bitrate:(CRBitrateType)bitrate;

- (void)switchRoom:(ClassRoomType)roomType room:(CRRoom *)room;

- (void)switchCamera:(CRCameraType)cameraType;

- (void)switchAudioRoute:(CRAudioType)audioType;

- (void)destroy;

@end
