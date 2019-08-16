//
//  ClientThread.m
//  SmartCar
//
//  Created by David Osollo on 7/13/19.
//  Copyright © 2019 David Osollo. All rights reserved.
//

#import "ClientThread.h"
UITextView *TCPIPtvUpdate;

@implementation ClientThread
-(void) InitializeClient:(const char*)sIP : (UITextView *)TCPIPtv
{
    int iFlagIPInfo=0;
    char *sIPPos;
    char sIPAddres[100];
    
    TCPIPtvUpdate = TCPIPtv;
    
    memset(sIPAddres,'\0',sizeof(sIPAddres));
    CFSocketContext sctx = {0,(__bridge void*) (self),NULL,NULL,NULL};
    obj_client=CFSocketCreate(kCFAllocatorDefault, AF_INET, SOCK_STREAM, IPPROTO_TCP, kCFSocketReadCallBack|kCFSocketConnectCallBack, TCPClientCallBackHandler,&sctx);

    struct sockaddr_in sock_addr;
    memset(&sock_addr,0,sizeof(sock_addr));
    sock_addr.sin_len=sizeof(sock_addr);
    sock_addr.sin_family=AF_INET;
    sock_addr.sin_port=htons(8888);
    sIPPos = strstr(sIP,"text");
    
    while(sIPPos && iFlagIPInfo <2)
    {
        if(iFlagIPInfo > 0 && *sIPPos != '\'')
        {
            strncat(sIPAddres,sIPPos,1);
        }
        if(*sIPPos=='\'')
        {
            iFlagIPInfo ++;
        }
        sIPPos++;
    }
    
    
//    strcpy(ss,sIP);
    inet_pton(AF_INET,sIPAddres, &sock_addr.sin_addr);
    CFDataRef dref=CFDataCreate(kCFAllocatorDefault, (UInt8*)&sock_addr, sizeof(sock_addr));
    CFSocketConnectToAddress(obj_client, dref, -1);
    CFRelease(dref);
    
}

-(void)main{
    CFRunLoopSourceRef loopref=CFSocketCreateRunLoopSource(kCFAllocatorDefault, obj_client, 0);
    CFRunLoopAddSource(CFRunLoopGetCurrent(), loopref, kCFRunLoopDefaultMode);
    CFRelease(loopref);
    CFRunLoopRun();
}

-(void) DisconnectFromServer{
    CFSocketInvalidate(obj_client);
    CFRelease(obj_client);
   // CFRunLoopRun();
}

-(void) SendTCPDataPacket:(const char*)data
{
    int initialize[1]={2}; //Initialize
    int data_length=(int)strlen(data);
    int target_length=snprintf(NULL,0,"%d",data_length);
    char *data_length_char=malloc(target_length+1);
    snprintf(data_length_char,target_length+1,"%d",data_length); //This line convert (45 into "45");
    
    int ele_count=(int)strlen(data_length_char);
    int *size_buff=(int*)malloc(ele_count*sizeof(int));
    
    for(int counter=0; counter<ele_count;counter++)
    {
        size_buff[counter]=(int)data_length_char[counter];
    }
    
    //int packet_length = 1+1+ele_count+(int)strlen(data);
    int packet_length = (int)strlen(data);
    UInt8 *packet=(UInt8*)malloc(packet_length * sizeof(UInt8));
    memcpy(&packet[0],initialize,1);
    
    for(int counter=0; counter<ele_count;counter++)
    {
        memcpy(&packet[counter+1],&size_buff[counter],1);
        
    }
    
    //memcpy(&packet[0+1+ele_count],separator,1);
    //memcpy(&packet[0+1+ele_count+1],data,strlen(data));
    memcpy(&packet[0],data,strlen(data));
    
    CFDataRef dref=CFDataCreate(kCFAllocatorDefault,packet,packet_length);
    CFSocketSendData(obj_client,NULL,dref,-1);
    free(packet);
    free(size_buff);
    free(data_length_char);
    CFRelease(dref);
    
}

-(void)InitializeNative:(CFSocketNativeHandle) native_socket{
    
    CFSocketContext sctx = {0,(__bridge void*) (self),NULL,NULL,NULL};
    obj_client=CFSocketCreateWithNative(kCFAllocatorDefault, native_socket, kCFSocketReadCallBack, TCPClientCallBackHandler, &sctx);
    
}

-(char*)ReadData
{
    char *data_buff;
    NSMutableString *buff_length=[[NSMutableString alloc]init];
    char buf[1];
    read(CFSocketGetNative(obj_client),buf,1);
    
    while((int)*buf!=4)
    {
        [buff_length appendFormat:@"%c",(char)(int)*buf];
        read(CFSocketGetNative(obj_client),&buf,1);
    }
    
    
    int data_length=[[buff_length stringByTrimmingCharactersInSet:[[NSCharacterSet decimalDigitCharacterSet]invertedSet]]intValue];
    
    data_buff=(char *)malloc(data_length*sizeof(char));
    ssize_t byte_read=0;
    ssize_t byte_offset=0;
    
    while(byte_offset<data_length)
    {
        byte_read=read(CFSocketGetNative(obj_client),data_buff+byte_offset,50);
        byte_offset+=byte_read;
        
    }
    return data_buff;
    
}


void  TCPClientCallBackHandler(CFSocketRef s, CFSocketCallBackType callbacktype, CFDataRef address, const void *data, void *info)
{
    static char sDataRec[MAX_READ_BUFF];
    static int iPosRecData=0;
    
    switch(callbacktype)
    {
            
        case kCFSocketConnectCallBack:
            if(data)
            {
                CFSocketIsValid(s);
                CFRelease(s);
                CFRunLoopStop(CFRunLoopGetCurrent());
                
            }
            else
            {
                NSLog(@"Client Connected to server");
            }
            break;
        case kCFSocketReadCallBack:{
            char buf[1];
            read(CFSocketGetNative(s),&buf,1);
            
            if(buf[0]!='\n')
            {
                sDataRec[iPosRecData] = buf[0];
                iPosRecData++;
            }
            else
            {
                //NSString *absolutePath = @"%s",(char *) sDataRec;
                //NSString *s = [NSString stringWithFormat:@"%s", sDataRec];
                //TCPIPtvUpdate.text;
                //TCPIPtvUpdate.text = [TCPIPtvUpdate.text stringByAppendingString:@"Hola\n\n"];
                TCPIPtvUpdate.text = [TCPIPtvUpdate.text stringByAppendingString : [NSString stringWithFormat:@"%s\n", sDataRec]];
                memset(sDataRec,0, MAX_READ_BUFF);
                iPosRecData=0;
               /* ClientThread * obj_client_ptr = (__bridge ClientThread*) info;
                char *recv_data=[obj_client_ptr ReadData];
                free(recv_data);*/

            }
        }
            break;
        default:
            break;
            
    }
    
}

@end
