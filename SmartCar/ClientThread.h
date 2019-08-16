//
//  ClientThread.h
//  SmartCar
//
//  Created by David Osollo on 7/13/19.
//  Copyright © 2019 David Osollo. All rights reserved.
//

#import <Foundation/Foundation.h>
#include <sys/socket.h>
#include <netinet/in.h>
#import <UIKit/UIKit.h>
#include <arpa/inet.h>
#define MAX_READ_BUFF 10000

NS_ASSUME_NONNULL_BEGIN

@interface ClientThread : NSThread{
    CFSocketRef obj_client;
    char sDataRead[MAX_READ_BUFF];
    int  iPosRead;

}

-(void)InitializeClient:(const char*)sIP : (UITextView *)TCPIPtv;
-(void)InitializeNative:(CFSocketNativeHandle) native_socket;
-(void)main;
-(void)DisconnectFromServer;
-(void)SendTCPDataPacket:(const char*)data;
-(char*)ReadData;

@end

NS_ASSUME_NONNULL_END
