//
//  ViewController.m
//  Classroom3
//
//  Created by ryan on 2017/4/24.
//  Copyright © 2017年 ryan. All rights reserved.
//

#import "ViewController.h"
#import "ClassRoomManager.h"

@interface ViewController ()

@property (weak, nonatomic) IBOutlet UIView *remoteView;
@property (weak, nonatomic) IBOutlet UIView *localView;

@property (nonatomic, strong) CRRoom *room;
@property (nonatomic, strong) ClassRoomManager *manager;

@end

@implementation ViewController {
    BOOL camera;
    BOOL audio;
    BOOL muteAudio;
    BOOL muteVideo;
}

- (CRRoom *)room {
    if (!_room) {
        NSString *userId = [@((NSUInteger)[[NSDate date] timeIntervalSince1970]) stringValue];
        _room = [[CRRoom alloc] initWithUrl:[NSURL URLWithString:@"wss://192.168.204.221:8000"] userId:userId roomId:@"27298" userType:1 userInfo:nil];
    }
    return _room;
}

- (void)viewDidLoad {
    [super viewDidLoad];
        
    _manager = [[ClassRoomManager alloc] init];
    [self.manager setVideoCapturer:self.localView remoteRender:self.remoteView];
    [self.manager setResolution:CRResolutionType240P codec:0 bitrate:0];
    [self.manager switchRoom:ClassRoomTypeKurento room:self.room];
}

- (IBAction)refresh:(id)sender {
}

- (IBAction)leave:(id)sender {
    [self.manager destroy];
    [self.navigationController popViewControllerAnimated:YES];
}

- (IBAction)switchCamera:(id)sender {
    [self.manager switchCamera: camera ? CRCameraTypeFront : CRCameraTypeBack];
    camera = !camera;
}

- (IBAction)switchAudio:(id)sender {
    [self.manager switchAudioRoute:audio ? CRAudioTypeDefault : CRAudioTypeSpeaker];
    audio = !audio;
}

- (IBAction)closeVideo:(id)sender {
    muteVideo = !muteVideo;
    //[self.manager muteLocalVideo:muteVideo];
}

- (IBAction)closeAudio:(id)sender {
    muteAudio = !muteAudio;
    //[self.manager muteLocalAudio:muteAudio];
}

- (IBAction)openCordova:(id)sender {

}

- (IBAction)clickSegment:(UISegmentedControl *)sender {
    switch (sender.selectedSegmentIndex) {
        case 0:
            [self.manager switchRoom:ClassRoomTypeKurento room:self.room];
            break;
        case 1:
            [self.manager switchRoom:ClassRoomTypeMediaSoup room:self.room];
            break;
        case 2:
            [self.manager switchRoom:ClassRoomTypeAgora room:self.room];
            break;
        default:
            break;
    }
}

- (void)didReceiveMemoryWarning {
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}


@end
