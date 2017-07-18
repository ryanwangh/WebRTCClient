//
//  main.m
//  Classroom3
//
//  Created by ryan on 2017/4/24.
//  Copyright © 2017年 ryan. All rights reserved.
//

#import <UIKit/UIKit.h>
#import "AppDelegate.h"

int main(int argc, char * argv[]) {
    @autoreleasepool {
        //socket在遇到管道破裂时会收到SIGPIPE信号,造成解锁黑屏,下面是忽略SIGPIPE信号
        //在网络异常的时候如果程序收到SIGPIRE是会直接被退出的。
        struct sigaction sa;
        sa.sa_handler = SIG_IGN;
        sigaction( SIGPIPE, &sa, 0 );
        
        //signal(SIGPIPE, SIG_IGN);
        return UIApplicationMain(argc, argv, nil, NSStringFromClass([AppDelegate class]));
    }
}
