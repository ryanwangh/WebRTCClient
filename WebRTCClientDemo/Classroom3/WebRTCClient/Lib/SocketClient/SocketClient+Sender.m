//
//  SocketClient+Sender.m
//  Classroom3
//
//  Created by ryan on 2017/4/24.
//  Copyright © 2017年 ryan. All rights reserved.
//

#import "SocketClient+Sender.h"
#import "CRRoom.h"

@implementation SocketClient (Sender)

- (void)tryJoin:(CRRoom *)room {
    [self send:@"tryJoin" data:room.items];
}

- (void)kickAndJoin:(CRRoom *)room {
    [self send:@"kickAndJoin" data:room.items];
}

- (void)leave:(CRRoom *)room {
    [self send:@"leave" data:room.items];
}

@end
