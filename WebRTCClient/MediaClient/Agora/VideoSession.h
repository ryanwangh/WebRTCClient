//
//  VideoSession.h
//  Classroom3
//
//  Created by ryan on 2017/6/20.
//  Copyright © 2017年 ryan. All rights reserved.
//

#import <Foundation/Foundation.h>

@class AgoraRtcVideoCanvas;

@interface VideoSession : NSObject

@property (nonatomic, assign, readonly) NSInteger uid;

@property (nonatomic, strong, readonly) UIView *renderView;

@property (nonatomic, strong, readonly) AgoraRtcVideoCanvas *canvas;

@property (nonatomic, assign, getter=isVideoMuted) BOOL videoMuted;

+ (instancetype)session;

- (instancetype)initWithUid:(NSInteger)uid;

- (void)layoutViews;

- (void)remove;

@end
