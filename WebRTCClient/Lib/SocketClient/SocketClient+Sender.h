//
//  SocketClient+Sender.h
//  Classroom3
//
//  Created by ryan on 2017/4/24.
//  Copyright © 2017年 ryan. All rights reserved.
//

#import "SocketClient.h"

@class CRRoom;

@interface SocketClient (Sender)

- (void)tryJoin:(CRRoom *)room;

- (void)kickAndJoin:(CRRoom *)room;

- (void)leave:(CRRoom *)room;

@end
