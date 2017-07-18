//
//  ClassRoomManager.m
//  Classroom3
//
//  Created by ryan on 2017/5/25.
//  Copyright © 2017年 ryan. All rights reserved.
//

#import "ClassRoomManager.h"
#import <WebRTC/WebRTC.h>
#import "KurentoClient.h"
#import "MediaSoupClient.h"
#import "AgoraClient.h"
#import "CRSetting.h"

@interface ClassRoomManager ()

@property (nonatomic, strong) UIView *localView;
@property (nonatomic, strong) UIView *remoteView;

@property (nonatomic, strong) CRRoom *room;
@property (nonatomic, assign) ClassRoomType roomType;

@property (nonatomic, strong) NSArray *roomClssses;
@property (nonatomic, strong) id<CRClientDelegate> currentClient;

@end

@implementation ClassRoomManager

+ (void)setup {
    NSDictionary *fieldTrials = @{
                                  kRTCFieldTrialH264HighProfileKey: kRTCFieldTrialEnabledValue,
                                  };
    RTCInitFieldTrialDictionary(fieldTrials);
    RTCInitializeSSL();
    RTCSetupInternalTracer();
    
#if defined(DEBUG)
    RTCSetMinDebugLogLevel(RTCLoggingSeverityError);
#endif
}

+ (void)clear {
    RTCShutdownInternalTracer();
    RTCCleanupSSL();
}

- (instancetype)init {
    if (self = [super init]) {
        _roomType = 0;
    }
    return self;
}

- (NSArray *)roomClssses {
    if (!_roomClssses) {
        _roomClssses = @[[KurentoClient class],
                         [MediaSoupClient class],
                         [AgoraClient class]
                         ];
    }
    return _roomClssses;
}

- (void)setVideoCapturer:(UIView *)localVideo remoteRender:(UIView *)remoteVideo {
    _localView = localVideo;
    _remoteView = remoteVideo;
}

- (void)setResolution:(CRResolutionType)resolution codec:(CRCodecType)codec bitrate:(CRBitrateType)bitrate {
    [CRSetting settingWithResolution:resolution codec:codec bitrate:bitrate];
}

- (id<CRClientDelegate>)createClientByType:(ClassRoomType) type {
    Class cls = self.roomClssses[type - 1];
    id<CRClientDelegate> client = [[cls alloc] initWithRoom:self.room];
    [client setVideoCapturer:self.localView remoteRender:self.remoteView];
    return client;
}

- (void)switchRoom:(ClassRoomType)roomType room:(CRRoom *)room {
    [self destroy];
    _roomType = roomType;
    _room = room;
    
    self.currentClient = [self createClientByType:roomType];
    [self.currentClient start];
}

- (void)switchCamera:(CRCameraType)cameraType {
    [self.currentClient switchCamera:cameraType];
}

- (void)switchAudioRoute:(CRAudioType)audioType {
    [self.currentClient switchAudioRoute:audioType];
}

- (void)destroy {
    [self.currentClient destroy];
}

@end

