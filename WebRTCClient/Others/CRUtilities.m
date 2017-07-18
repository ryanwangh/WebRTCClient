//
//  CRUtilities.m
//  Classroom3
//
//  Created by ryan on 2017/5/8.
//  Copyright © 2017年 ryan. All rights reserved.
//

#import "CRUtilities.h"

@implementation RTCMediaConstraints (constraints)

+ (NSDictionary *)offerOptions:(BOOL)isSender {
    return @{
             @"OfferToReceiveAudio": isSender ? @"false" : @"true",
             @"OfferToReceiveVideo": isSender ? @"false" : @"true" };
}

+ (NSDictionary *)optionalConstraints{
    return @{
             //@"internalSctpDataChannels": @"true",
             @"DtlsSrtpKeyAgreement": @"true" };
}

+ (RTCMediaConstraints *)connectionConstraints {
    return [[RTCMediaConstraints alloc] initWithMandatoryConstraints:nil
                                                 optionalConstraints:[RTCMediaConstraints optionalConstraints]];
}

+ (RTCMediaConstraints *)offerConstraints:(BOOL)isSender {
    return [[RTCMediaConstraints alloc] initWithMandatoryConstraints:[RTCMediaConstraints offerOptions:isSender]
                                                 optionalConstraints:nil];
}

+ (RTCMediaConstraints *)answerConstraints {
    return [RTCMediaConstraints offerConstraints:YES];
}

+ (RTCMediaConstraints *)audioConstraints {
    NSDictionary *mandatoryConstraints = @{
                                           kRTCMediaConstraintsLevelControl : kRTCMediaConstraintsValueFalse };
    RTCMediaConstraints *constraints =
    [[RTCMediaConstraints alloc] initWithMandatoryConstraints:mandatoryConstraints
                                          optionalConstraints:nil];
    return constraints;
}

+ (RTCMediaConstraints *)videoConstraints {
    NSDictionary *mandatoryConstraints = @{
//                                           kRTCMediaConstraintsMaxWidth : @"1280",
//                                           kRTCMediaConstraintsMaxHeight: @"960",
                                           kRTCMediaConstraintsMinWidth: @"640",
                                           kRTCMediaConstraintsMinHeight: @"480",
//                                           kRTCMediaConstraintsMaxFrameRate: @"15",
//                                           kRTCMediaConstraintsMinFrameRate: @"15"
                                           };
    NSString *aspectRatio = [NSString stringWithFormat:@"%f",(double)4/3];
    NSDictionary *optionalConstraints = @{
                                          kRTCMediaConstraintsMinAspectRatio: aspectRatio,
                                          };
    
    RTCMediaConstraints *constraints = [[RTCMediaConstraints alloc] initWithMandatoryConstraints:mandatoryConstraints
                                                                             optionalConstraints:optionalConstraints];
    return constraints;
}

@end

@implementation RTCSessionDescription (sdp)

+ (RTCSessionDescription *)updateBandwidthRestriction:(RTCSessionDescription *)sessionDescription bandwidth:(NSUInteger)bandwidth {
    NSString *sdp = sessionDescription.sdp;
    NSString *mVideoLinePattern = @"m=video(.*)";
    NSString *cLinePattern = @"c=IN(.*)";
    NSError *error = nil;
    NSRegularExpression *mRegex = [[NSRegularExpression alloc] initWithPattern:mVideoLinePattern options:0 error:&error];
    NSRegularExpression *cRegex = [[NSRegularExpression alloc] initWithPattern:cLinePattern options:0 error:&error];
    NSRange mLineRange = [mRegex rangeOfFirstMatchInString:sdp options:NSMatchingWithoutAnchoringBounds range:NSMakeRange(0, [sdp length])];
    NSRange cLineSearchRange = NSMakeRange(mLineRange.location + mLineRange.length, [sdp length] - (mLineRange.location + mLineRange.length));
    NSRange cLineRange = [cRegex rangeOfFirstMatchInString:sdp options:NSMatchingWithoutAnchoringBounds range:cLineSearchRange];
    
    NSString *cLineString = [sdp substringWithRange:cLineRange];
    NSString *bandwidthString = [NSString stringWithFormat:@"b=AS:%d", (int)bandwidth];
    
    NSString *sdpString = [sdp stringByReplacingCharactersInRange:cLineRange
                                                       withString:[NSString stringWithFormat:@"%@\n%@", cLineString, bandwidthString]];
    return [[RTCSessionDescription alloc] initWithType:sessionDescription.type sdp:sdpString];
}


+ (RTCSessionDescription *)updateCodecForDescription:(RTCSessionDescription *)description preferredVideoCodec:(NSString *)codec {
    NSString *sdpString = description.sdp;
    NSString *lineSeparator = @"\n";
    NSString *mLineSeparator = @" ";
    // Copied from PeerConnectionClient.java.
    // TODO(tkchin): Move this to a shared C++ file.
    NSMutableArray *lines =
    [NSMutableArray arrayWithArray:
     [sdpString componentsSeparatedByString:lineSeparator]];
    // Find the line starting with "m=video".
    NSInteger mLineIndex = -1;
    for (NSInteger i = 0; i < lines.count; ++i) {
        if ([lines[i] hasPrefix:@"m=video"]) {
            mLineIndex = i;
            break;
        }
    }
    if (mLineIndex == -1) {
        NSLog(@"No m=video line, so can't prefer %@", codec);
        return description;
    }
    // An array with all payload types with name |codec|. The payload types are
    // integers in the range 96-127, but they are stored as strings here.
    NSMutableArray *codecPayloadTypes = [[NSMutableArray alloc] init];
    // a=rtpmap:<payload type> <encoding name>/<clock rate>
    // [/<encoding parameters>]
    NSString *pattern =
    [NSString stringWithFormat:@"^a=rtpmap:(\\d+) %@(/\\d+)+[\r]?$", codec];
    NSRegularExpression *regex =
    [NSRegularExpression regularExpressionWithPattern:pattern
                                              options:0
                                                error:nil];
    for (NSString *line in lines) {
        NSTextCheckingResult *codecMatches =
        [regex firstMatchInString:line
                          options:0
                            range:NSMakeRange(0, line.length)];
        if (codecMatches) {
            [codecPayloadTypes
             addObject:[line substringWithRange:[codecMatches rangeAtIndex:1]]];
        }
    }
    if ([codecPayloadTypes count] == 0) {
        NSLog(@"No payload types with name %@", codec);
        return description;
    }
    NSArray *origMLineParts =
    [lines[mLineIndex] componentsSeparatedByString:mLineSeparator];
    // The format of ML should be: m=<media> <port> <proto> <fmt> ...
    const int kHeaderLength = 3;
    if (origMLineParts.count <= kHeaderLength) {
        RTCLogWarning(@"Wrong SDP media description format: %@", lines[mLineIndex]);
        return description;
    }
    // Split the line into header and payloadTypes.
    NSRange headerRange = NSMakeRange(0, kHeaderLength);
    NSRange payloadRange =
    NSMakeRange(kHeaderLength, origMLineParts.count - kHeaderLength);
    NSArray *header = [origMLineParts subarrayWithRange:headerRange];
    NSMutableArray *payloadTypes = [NSMutableArray
                                    arrayWithArray:[origMLineParts subarrayWithRange:payloadRange]];
    // Reconstruct the line with |codecPayloadTypes| moved to the beginning of the
    // payload types.
    NSMutableArray *newMLineParts = [NSMutableArray arrayWithCapacity:origMLineParts.count];
    [newMLineParts addObjectsFromArray:header];
    [newMLineParts addObjectsFromArray:codecPayloadTypes];
    [payloadTypes removeObjectsInArray:codecPayloadTypes];
    [newMLineParts addObjectsFromArray:payloadTypes];
    
    NSString *newMLine = [newMLineParts componentsJoinedByString:mLineSeparator];
    [lines replaceObjectAtIndex:mLineIndex
                     withObject:newMLine];
    
    NSString *mangledSdpString = [lines componentsJoinedByString:lineSeparator];
    return [[RTCSessionDescription alloc] initWithType:description.type
                                                   sdp:mangledSdpString];
}

+ (RTCSessionDescription *)sdpWithInfo:(NSDictionary *)info {
    NSString *type = info[@"type"];
    NSString *sdp = info[@"sdp"];
    if (NullString(type) || NullString(sdp)) {
        return nil;
    }
    
    RTCSdpType sdpType = 0;
    if ([type isEqualToString:@"offer"]) {
        sdpType = RTCSdpTypeOffer;
    } else if ([type isEqualToString:@"answer"]) {
        sdpType = RTCSdpTypeAnswer;
    }
    return [[RTCSessionDescription alloc] initWithType:sdpType sdp:sdp];
}

- (NSDictionary *)info {
    NSString *typeString = @"";
    switch (self.type) {
        case RTCSdpTypeOffer:
            typeString = @"offer";
            break;
        case RTCSdpTypeAnswer:
            typeString = @"answer";
            break;
        default:
            break;
    }
    return @{@"type": typeString,
             @"sdp": self.sdp};
}

@end

@implementation RTCIceCandidate (candidate)

+ (RTCIceCandidate *)candicdateWithInfo:(NSDictionary *)info {
    NSString *candidate = info[@"candidate"];
    int sdpMLineIndex = (int)[info[@"sdpMLineIndex"] integerValue];
    NSString *sdpMid = info[@"sdpMid"];
    return [[RTCIceCandidate alloc] initWithSdp:candidate sdpMLineIndex:sdpMLineIndex sdpMid:sdpMid];
}

- (NSDictionary *)info {
    return @{@"candidate": self.sdp,
             @"sdpMid": self.sdpMid,
             @"sdpMLineIndex": @(self.sdpMLineIndex),
             };
}

@end

@implementation CRUtilities

- (NSArray *)getDevicesByType:(NSString *)mediaType {
    
    NSArray *devices = [AVCaptureDevice devicesWithMediaType:mediaType];
    NSMutableArray *deviceLists = [NSMutableArray arrayWithCapacity:devices.count];
    
    for (AVCaptureDevice* captureDevice in devices) {
        NSDictionary *deviceInfo = @{@"deviceId":captureDevice.uniqueID,
                                     @"groupId":@"",
                                     @"label":captureDevice.localizedName};
        [deviceLists addObject:deviceInfo];
    }
    
    return [deviceLists copy];
}

- (NSDictionary *)getDevices {
    NSArray *audioList = [self getDevicesByType:AVMediaTypeAudio];
    NSArray *videoList = [self getDevicesByType:AVMediaTypeVideo];
    return @{@"audio": audioList,@"video":videoList,@"audiooutput":@[]};
}

@end
