//
//  CRStream.m
//  Classroom3
//
//  Created by ryan on 2017/4/24.
//  Copyright © 2017年 ryan. All rights reserved.
//

#import "CRStream.h"
#import <WebRTC/WebRTC.h>
#import "CRSetting.h"
#import "CRPeer.h"

static NSString * const kARDMediaStreamId = @"ARDAMS";
static NSString * const kARDAudioTrackId = @"ARDAMSa0";
static NSString * const kARDVideoTrackId = @"ARDAMSv0";

@implementation CRCapturer {
    BOOL _usingFrontCamera;
    CRSetting *setting;
}

- (instancetype)initWithCapturer:(RTCCameraVideoCapturer *)capturer {
    if (self = [super init]) {
        _capturer = capturer;
        _usingFrontCamera = YES;
        setting = [[CRSetting alloc] init];
    }
    return self;
}

- (void)startCapture {
    AVCaptureDevice *device = [self findDevice];
    AVCaptureDeviceFormat *format = [self selectFormatForDevice:device];
    NSInteger fps = [self selectFpsForFormat:format];
    [_capturer startCaptureWithDevice:device format:format fps:fps];
}

- (void)stopCapture {
    [_capturer stopCapture];
    _videoTrack = nil;
}

- (void)switchCamera:(CRCameraType)cameraType {
    _usingFrontCamera = cameraType == CRCameraTypeFront ? YES : NO;
    [self startCapture];
}

- (void)switchAudioRoute:(CRAudioType)audioType {
    AVAudioSessionPortOverride override = audioType == CRAudioTypeSpeaker ? AVAudioSessionPortOverrideSpeaker : AVAudioSessionPortOverrideNone;
    [RTCDispatcher dispatchAsyncOnType:RTCDispatcherTypeAudioSession
                                 block:^{
                                     //RTCAudioSession *session = [RTCAudioSession sharedInstance];
                                     //[session lockForConfiguration];
                                     NSError *error = nil;
                                     if (![[AVAudioSession sharedInstance] overrideOutputAudioPort:override error:&error]) {
                                         RTCLogError(@"Error overriding output port: %@",
                                                     error.localizedDescription);
                                     }
                                     //[session unlockForConfiguration];
                                 }];
}

#pragma mark - privates

- (AVCaptureDevice *)findDevice{
    AVCaptureDevicePosition position = _usingFrontCamera ? AVCaptureDevicePositionFront : AVCaptureDevicePositionBack;
    NSArray<AVCaptureDevice *> *captureDevices = [RTCCameraVideoCapturer captureDevices];
    for (AVCaptureDevice *device in captureDevices) {
        if (device.position == position) return device;
    }
    return captureDevices[0];
}

- (AVCaptureDeviceFormat *)selectFormatForDevice:(AVCaptureDevice *)device {
    NSArray<AVCaptureDeviceFormat *> *formats =
    [RTCCameraVideoCapturer supportedFormatsForDevice:device];
    int targetWidth = [setting currentVideoResolution].width;
    int targetHeight = [setting currentVideoResolution].height;
    AVCaptureDeviceFormat *selectedFormat = nil;
    int currentDiff = INT_MAX;
    
    for (AVCaptureDeviceFormat *format in formats) {
        CMVideoDimensions dimension = CMVideoFormatDescriptionGetDimensions(format.formatDescription);
        int diff = abs(targetWidth - dimension.width) + abs(targetHeight - dimension.height);
        if (diff < currentDiff) {
            selectedFormat = format;
            currentDiff = diff;
        }
    }
    
    NSAssert(selectedFormat != nil, @"No suitable capture format found.");
    return selectedFormat;
}

- (NSInteger)selectFpsForFormat:(AVCaptureDeviceFormat *)format {
    Float64 maxFramerate = 0;
    for (AVFrameRateRange *fpsRange in format.videoSupportedFrameRateRanges) {
        maxFramerate = fmax(maxFramerate, fpsRange.maxFrameRate);
    }
    return maxFramerate;
}

@end

@interface CRRenderer () <RTCEAGLVideoViewDelegate>

@property (nonatomic, weak) CRCapturer *localCapturer;
@property (nonatomic, strong) RTCVideoTrack *localVideoTrack;
@property (atomic, strong, readonly) RTCCameraPreviewView *localVideoView;

@property (nonatomic, assign) CGSize remoteVideoSize;
@property (nonatomic, strong) RTCVideoTrack *remoteVideoTrack;
@property (atomic, strong, readonly) __kindof UIView<RTCVideoRenderer> *remoteVideoView;

@end

@implementation CRRenderer

@synthesize remoteVideoView = _remoteVideoView;

- (void)dealloc {
    _delegate = nil;
}

+ (CRRenderer *)rendererForTrack:(RTCVideoTrack *)videoTrack frame:(CGRect)frame {
    CRRenderer *render = [[CRRenderer alloc] initWithVideoTrack:videoTrack frame:frame];
    return render;
}

+ (CRRenderer *)rendererForCapturer:(CRCapturer *)capturer frame:(CGRect)frame{
    CRRenderer *render = [[CRRenderer alloc] initWithCapturer:capturer frame:frame];
    render.localVideoView.captureSession = capturer.capturer.captureSession;
    return render;
}

- (instancetype)initWithCapturer:(CRCapturer *)capturer frame:(CGRect)frame {
    self = [super initWithFrame:frame];
    if (self) {
        _localCapturer = capturer;
        _localVideoView = [[RTCCameraPreviewView alloc] initWithFrame:frame];
        //((AVCaptureVideoPreviewLayer *)_localVideoView.layer).videoGravity = AVLayerVideoGravityResizeAspectFill;
        [self addSubview:_localVideoView];
    }
    return self;
}

- (instancetype)initWithVideoTrack:(RTCVideoTrack *)videoTrack frame:(CGRect)frame {
    if (self = [super initWithFrame:frame]) {
#if defined(RTC_SUPPORTS_METAL)
        _remoteVideoView = [[RTCMTLVideoView alloc] initWithFrame:CGRectZero];
#else
        RTCEAGLVideoView *remoteView = [[RTCEAGLVideoView alloc] initWithFrame:CGRectZero];
        remoteView.delegate = self;
        _remoteVideoView = remoteView;
#endif
        [self addSubview:_remoteVideoView];
        [self addRemoteVideoTrack:videoTrack];
    }
    return self;
}

- (void)addRemoteVideoTrack:(RTCVideoTrack *)remoteVideoTrack {
    [self removeRender];
    _remoteVideoTrack = remoteVideoTrack;
    [_remoteVideoTrack addRenderer:_remoteVideoView];
}

- (void)removeRender {
    if (_remoteVideoView) {
        [_remoteVideoTrack removeRenderer:_remoteVideoView];
        _remoteVideoTrack = nil;
        [_remoteVideoView renderFrame:nil];
    } else {
        
    }
}

- (void)remove {
    if (_remoteVideoView) {
        [self removeRender];
        [_remoteVideoView removeFromSuperview];
    } else {
        [_localCapturer stopCapture];
        [_localVideoView removeFromSuperview];
    }
    [self removeFromSuperview];
}

- (void)layoutSubviews {
    [super layoutSubviews];
    
    CGRect bounds = self.bounds;
    CGSize videoSize = self.remoteVideoSize;
    CGRect videoFrame = bounds;
    
    if (!CGSizeEqualToSize(videoSize, CGSizeZero)) {
        videoFrame = AVMakeRectWithAspectRatioInsideRect(videoSize, bounds);
    }
    
    self.remoteVideoView.frame = videoFrame;
}

#pragma mark - RTCEAGLVideoViewDelegate

- (void)videoView:(RTCEAGLVideoView*)videoView didChangeVideoSize:(CGSize)size {
    if (videoView == self.remoteVideoView) {
        _remoteVideoSize = size;
    }
    if ([self.delegate respondsToSelector:@selector(renderer:streamDimensionsDidChange:)]) {
        [self.delegate renderer:self streamDimensionsDidChange:size];
    }
    [self setNeedsLayout];
}

@end


@interface CRStream ()

@property (nonatomic, weak) RTCPeerConnection *peerConnection;

@property (nonatomic, weak) RTCPeerConnectionFactory *peerFactory;

@property (nonatomic, strong) CRCapturer *capturer;

@property (nonatomic, copy) void (^completion)(CRCapturer *capturer);

@end

@implementation CRStream

+ (instancetype)streamWithPeer:(CRPeer *)peer {
    return [[CRStream alloc] initWithPeer:peer];
}

- (instancetype)initWithPeer:(CRPeer *)peer {
    self = [super init];
    if (self) {
        _peerConnection = peer.peerConnection;
        _peerFactory = peer.peerFactory;
    }
    return self;
}

- (BOOL)getUserMedia:(void (^)(CRCapturer *))completion {
    self.completion = completion;
    
    //Audio setup
    BOOL audioEnabled = NO;
    AVAuthorizationStatus audioAuthStatus = [AVCaptureDevice authorizationStatusForMediaType:AVMediaTypeAudio];
    if (audioAuthStatus == AVAuthorizationStatusAuthorized || audioAuthStatus == AVAuthorizationStatusNotDetermined) {
        audioEnabled = YES;
        [self createAudioSender];
    }
    
    //Video setup
    BOOL videoEnabled = NO;
    AVAuthorizationStatus videoAuthStatus = [AVCaptureDevice authorizationStatusForMediaType:AVMediaTypeVideo];
    if (videoAuthStatus == AVAuthorizationStatusAuthorized || videoAuthStatus == AVAuthorizationStatusNotDetermined) {
        videoEnabled = YES;
        [self createVideoSender];
        if (self.completion) self.completion(self.capturer);
    }
    return audioEnabled && videoEnabled;
}

- (RTCRtpSender *)createAudioSender {
    RTCAudioSource *source = [self.peerFactory audioSourceWithConstraints:[RTCMediaConstraints audioConstraints]];
    RTCAudioTrack *track = [self.peerFactory audioTrackWithSource:source
                                                  trackId:kARDAudioTrackId];
    
    RTCRtpSender *sender = [self.peerConnection senderWithKind:kRTCMediaStreamTrackKindAudio streamId:kARDMediaStreamId];
    sender.track = track;
    return sender;
}

- (RTCRtpSender *)createVideoSender {
    RTCRtpSender *videoSender = [self.peerConnection senderWithKind:kRTCMediaStreamTrackKindVideo streamId:kARDMediaStreamId];
    videoSender.track = [self createLocalVideoTrack];
    return videoSender;
}

- (RTCVideoTrack *)createLocalVideoTrack {
    RTCVideoTrack* localVideoTrack = nil;
    CRCapturer *capturer = nil;
#if !TARGET_IPHONE_SIMULATOR
    RTCVideoSource *source = [self.peerFactory videoSource];
    localVideoTrack = [self.peerFactory videoTrackWithSource:source trackId:kARDVideoTrackId];
    
    RTCCameraVideoCapturer *cameraCapturer = [[RTCCameraVideoCapturer alloc] initWithDelegate:source];
    capturer = [[CRCapturer alloc] initWithCapturer:cameraCapturer];
    capturer.videoTrack = localVideoTrack;
    _capturer = capturer;
#endif
    return localVideoTrack;
}

@end
