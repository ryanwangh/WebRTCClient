
//
//  CRTypes.h
//  Classroom3
//
//  Created by ryan on 2017/5/23.
//  Copyright © 2017年 ryan. All rights reserved.
//

typedef NS_ENUM(NSUInteger, CRResolutionType) {
    CRResolutionType240P = 1,//320x240
    CRResolutionType480P = 2,//640x480
    CRResolutionType540P = 3,//960x540
    CRResolutionType720P = 4//1280x720
};

typedef NS_ENUM(NSUInteger, CRCodecType) {
    CRCodecTypeH264 = 1,
    CRCodecTypeVP8 = 2,
    CRCodecTypeVP9 = 3
};

typedef NS_ENUM(NSUInteger, CRBitrateType) {
    CRBitrateType15 = 1,//15
    CRBitrateType30 = 2,//30
    CRBitrateType60 = 3//60
};

typedef NS_ENUM(NSUInteger, CRCameraType) {
    CRCameraTypeFront = 1,//前置摄像头
    CRCameraTypeBack = 2//后置
};

typedef NS_ENUM(NSUInteger, CRAudioType) {
    CRAudioTypeDefault = 1,//扬声器
    CRAudioTypeSpeaker = 2//听筒
};

typedef NS_ENUM(NSInteger,CRUserType) {
    CRUserTypeTourist = 0,//游客
    CRUserTypeTeacher,//老师
    CRUserTypeStudent,//学生
    CRUserTypeManager,//管理员
    CRUserTypeParent,//家长
    CRUserTypeTechnology,//技术
    CRUserTypeEdu,//教务
    CRUserTypeSales//销售
};

typedef NS_ENUM(NSUInteger, CRMessageRoleType) {
    CRMessageRoleTypeSender = 1,//发送
    CRMessageRoleTypeRecver = 2//接收
};

typedef NS_ENUM(NSUInteger, CRMessageActionType) {
    //send 发送视频流
    CRMessageActionTypeSend = 1,
    //recv 接受视频流
    CRMessageActionTypeRecv = 2,
    //stop 停止发送视频流
    CRMessageActionTypeStop = 3,
    //
    CRMessageActionTypeStopAll = 4,
    //
    CRMessageActionTypeReset = 5,
    //sdpAnswerResponse
    CRMessageActionTypeAnswer = 6,
    //iceCandidateResponse
    CRMessageActionTypeCandidate = 7,
};

