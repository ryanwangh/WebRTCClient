//
//  VideoSession.m
//  Classroom3
//
//  Created by ryan on 2017/6/20.
//  Copyright © 2017年 ryan. All rights reserved.
//

#import "VideoSession.h"
#import <AgoraRtcEngineKit/AgoraRtcEngineKit.h>

@interface VideoSession ()

@end

@implementation VideoSession

+ (instancetype)session {
    return [[VideoSession alloc] initWithUid:0];
}

- (instancetype)initWithUid:(NSInteger)uid {
    if (self = [super init]) {
        _uid = uid;
        
        _renderView = [[UIView alloc] init];
        
        _canvas = [[AgoraRtcVideoCanvas alloc] init];
        _canvas.uid = uid;
        _canvas.view = _renderView;
        _canvas.renderMode = AgoraRtc_Render_Hidden;
    }
    return self;
}

- (void)setVideoMuted:(BOOL)videoMuted {
    _renderView.hidden = videoMuted;
}

- (void)layoutViews {
    _renderView.frame = _renderView.superview.bounds;
}

- (void)remove {
    [self.renderView removeFromSuperview];
}

@end
