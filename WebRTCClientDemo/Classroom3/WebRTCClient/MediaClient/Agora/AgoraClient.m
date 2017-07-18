//
//  AgoraClient.m
//  Classroom3
//
//  Created by ryan on 2017/6/20.
//  Copyright © 2017年 ryan. All rights reserved.
//

#import "AgoraClient.h"
#import <AgoraRtcEngineKit/AgoraRtcEngineKit.h>
#import "VideoSession.h"
#import "CRRoom.h"

#define AGORA_APPID @"557ae3cd7ab94ecfb4eaec20d03f2ead"

@interface AgoraClient () <AgoraRtcEngineDelegate>

@property (nonatomic, strong) AgoraRtcEngineKit *agoraKit;

@property (nonatomic, assign) NSInteger dataChannelId;

@property (nonatomic, strong) NSMutableArray *videoSessions;

@end

@implementation AgoraClient

@synthesize room = _room;

- (instancetype)initWithRoom:(CRRoom *)room {
    if (self = [super initWithRoom:room]) {
        _dataChannelId = -1;
        _videoSessions = [NSMutableArray arrayWithCapacity:2];
    }
    return self;
}

- (void)start {
    [self loadAgoraKit];
}

- (void)switchCamera:(CRCameraType)cameraType {
    [self.agoraKit switchCamera];
}

- (void)switchAudioRoute:(CRAudioType)audioType {
    [self.agoraKit setEnableSpeakerphone:YES];
}

- (void)destroy {
    [self leaveChannel];
}

- (void)loadAgoraKit {
    _agoraKit = [AgoraRtcEngineKit sharedEngineWithAppId:AGORA_APPID delegate:self];
    [_agoraKit setChannelProfile:AgoraRtc_ChannelProfile_Communication];
    [_agoraKit enableVideo];
    [_agoraKit setVideoProfile:AgoraRtc_VideoProfile_360P swapWidthAndHeight:NO];
    
    [self addLocalSession];
    [_agoraKit startPreview];
    
//    [_agoraKit setEncryptionMode:@"aes-128-xts"];
//    [_agoraKit setEncryptionSecret:@""];
    
    NSInteger code = [_agoraKit joinChannelByKey:nil channelName:_room.roomId info:nil uid:0 joinSuccess:^(NSString *channel, NSUInteger uid, NSInteger elapsed) {
        
    }];
    
    if (code == 0) {
        [self setIdleTimerActive:NO];
    } else {
        NSLog(@"failed");
    }
    
    [_agoraKit createDataStream:&_dataChannelId reliable:YES ordered:YES];
}

- (void)addLocalSession {
    VideoSession *session = [VideoSession session];
    [self.localVideo addSubview:session.renderView];
    [session layoutViews];
    [_videoSessions addObject:session];
    [_agoraKit setupLocalVideo:session.canvas];
}

- (void)addRemoteSession:(NSInteger)uid {
    VideoSession *session = [self createVideoSession:uid];
    [self.remoteVideo addSubview:session.renderView];
    [session layoutViews];
    [_agoraKit setupRemoteVideo:session.canvas];
}

- (VideoSession *)fetchSession:(NSInteger)uid {
    for (VideoSession *session in _videoSessions) {
        if (session.uid == uid) {
            return session;
        }
    }
    return nil;
}

- (VideoSession *)createVideoSession:(NSInteger)uid {
    VideoSession *session = [self fetchSession:uid];
    if (session) {
        return session;
    } else {
        VideoSession *newSession = [[VideoSession alloc] initWithUid:uid];
        [_videoSessions addObject:newSession];
        return newSession;
    }
}

- (void)removeVideoSession:(NSInteger)uid {
    VideoSession *session = [self fetchSession:uid];
    if (session) {
        [_videoSessions removeObject:session];
        [session remove];
    }
}

- (void)setVideoMuted:(BOOL)muted uid:(NSInteger)uid {
    VideoSession *session = [self fetchSession:uid];
    session.videoMuted = muted;
}

- (void)leaveChannel {
    [_agoraKit setupLocalVideo:nil];
    [_agoraKit leaveChannel:nil];
    [_agoraKit stopPreview];
    
    for (VideoSession *session in _videoSessions) {
        [session.renderView removeFromSuperview];
    }
    [_videoSessions removeAllObjects];
    //[self setIdleTimerActive:YES];
}

- (void)setIdleTimerActive:(BOOL)active {
    [[UIApplication sharedApplication] setIdleTimerDisabled:!active];
}

#pragma mark - AgoraRtcEngineDelegate

- (void)rtcEngine:(AgoraRtcEngineKit *)engine firstRemoteVideoDecodedOfUid:(NSUInteger)uid size:(CGSize)size elapsed:(NSInteger)elapsed {
    [self addRemoteSession:uid];
}

- (void)rtcEngine:(AgoraRtcEngineKit *)engine firstLocalVideoFrameWithSize:(CGSize)size elapsed:(NSInteger)elapsed {
    
}

- (void)rtcEngine:(AgoraRtcEngineKit *)engine didOfflineOfUid:(NSUInteger)uid reason:(AgoraRtcUserOfflineReason)reason {
    
}

- (void)rtcEngine:(AgoraRtcEngineKit *)engine didVideoMuted:(BOOL)muted byUid:(NSUInteger)uid {
    [self setVideoMuted:muted uid:uid];
}

- (void)rtcEngine:(AgoraRtcEngineKit *)engine remoteVideoStats:(AgoraRtcRemoteVideoStats *)stats {
    
}

- (void)rtcEngine:(AgoraRtcEngineKit *)engine didOccurError:(AgoraRtcErrorCode)errorCode {
    NSLog(@"");
}

@end
