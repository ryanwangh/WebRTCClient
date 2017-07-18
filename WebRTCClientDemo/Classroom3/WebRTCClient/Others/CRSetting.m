//
//  CRSetting.m
//  Classroom3
//
//  Created by ryan on 2017/5/19.
//  Copyright © 2017年 ryan. All rights reserved.
//

#import "CRSetting.h"

#define Storage [NSUserDefaults standardUserDefaults]

static NSString *const kVideoResolutionKey = @"rtc_video_resolution_key";
static NSString *const kVideoCodecKey = @"rtc_video_codec_key";
static NSString *const kVideoBitrateKey = @"rtc_max_bitrate_key";

static NSArray<NSString *> *videoResolutionsStaticValues() {
    return @[ @"320x240", @"640x480", @"960x540", @"1280x720" ];
}

static NSArray<NSString *> *videoCodecsStaticValues() {
    return @[ @"H264", @"VP8", @"VP9" ];
}

static NSArray<NSNumber *> *videoBitratesStaticValues() {
    return @[ @15, @30, @60 ];
}

@implementation CRSetting

+ (instancetype)settingWithResolution:(CRResolutionType)resolution codec:(CRCodecType)codec bitrate:(CRBitrateType)bitrate {
    CRSetting *setting = [[CRSetting alloc] init];
    if (resolution) [Storage setObject:videoResolutionsStaticValues()[resolution] forKey:kVideoResolutionKey];
    if (codec) [Storage setObject:videoCodecsStaticValues()[codec] forKey:kVideoCodecKey];
    if (bitrate) [Storage setObject:videoBitratesStaticValues()[bitrate] forKey:kVideoBitrateKey];
    return setting;
}

- (CGSize)currentVideoResolution {
    NSString *resolution = [Storage objectForKey:kVideoResolutionKey];
    if (!resolution) {
        resolution = [self defaultVideoResolution];
        [Storage setObject:resolution forKey:kVideoResolutionKey];
    }
    NSArray *components = [resolution componentsSeparatedByString:@"x"];
    return CGSizeMake([components[0] intValue], [components[1] intValue]);
}

- (NSString *)currentVideoCodec {
    NSString *codec = [Storage objectForKey:kVideoCodecKey];
    if (!codec) {
        codec = [self defaultVideoCodec];
        [Storage setObject:codec forKey:kVideoCodecKey];
    }
    return codec;
}

- (NSNumber *)currentMaxBitrate {
    NSNumber *bitrate = [Storage objectForKey:kVideoBitrateKey];
    if (!bitrate) {
        bitrate = [self defaultBitrate];
        [Storage setObject:bitrate forKey:kVideoBitrateKey];
    }
    return bitrate;
}

- (NSString *)defaultVideoResolution {
    return videoResolutionsStaticValues()[1];
}

- (NSString *)defaultVideoCodec {
    return videoCodecsStaticValues()[1];
}

- (NSNumber *)defaultBitrate {
    return @15;
}

- (NSArray<NSString *> *)availableVideoResolutions {
    return  videoResolutionsStaticValues();
}

- (NSArray<NSString *> *)availableVideoCodecs {
    return videoCodecsStaticValues();
}

@end
