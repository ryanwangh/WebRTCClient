//
//  CRStream.h
//  Classroom3
//
//  Created by ryan on 2017/4/24.
//  Copyright © 2017年 ryan. All rights reserved.
//

#import <Foundation/Foundation.h>
#import <WebRTC/RTCVideoRenderer.h>
#import "CRTypes.h"

@class RTCVideoTrack;
@class RTCCameraPreviewView;
@class RTCCameraVideoCapturer;
@class CRPeer;

@protocol CRRendererDelegate;

@interface CRCapturer : NSObject

@property (nonatomic, strong, readonly) RTCCameraVideoCapturer *capturer;
@property (nonatomic, strong) RTCVideoTrack *videoTrack;

- (instancetype)initWithCapturer:(RTCCameraVideoCapturer *)capturer;

- (void)startCapture;

- (void)stopCapture;

- (void)switchCamera:(CRCameraType)cameraType;

- (void)switchAudioRoute:(CRAudioType)audioType;

@end

@interface CRRenderer : UIView

@property (nonatomic, weak) id<CRRendererDelegate> delegate;

+ (CRRenderer *)rendererForCapturer:(CRCapturer *)capturer frame:(CGRect)frame;

+ (CRRenderer *)rendererForTrack:(RTCVideoTrack *)videoTrack frame:(CGRect)frame;

- (instancetype)initWithCapturer:(CRCapturer *)capturer frame:(CGRect)frame;

- (instancetype)initWithVideoTrack:(RTCVideoTrack *)videoTrack frame:(CGRect)frame;

- (void)remove;

@end

@protocol CRRendererDelegate <NSObject>

@optional

- (void)renderer:(CRRenderer *)renderer streamDimensionsDidChange:(CGSize)dimensions;

@end

@interface CRStream : NSObject

+ (instancetype)streamWithPeer:(CRPeer *)peer;

- (BOOL)getUserMedia:(void(^)(CRCapturer *capturer))completion;

@end
