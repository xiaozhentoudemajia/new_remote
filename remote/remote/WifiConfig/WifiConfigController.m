//
//  WifiConfig.m
//  AcaRemote
//
//  Created by ALI_MAC on 2017/10/13.
//

#import "WifiConfigController.h"

#define BROADCAST_PORT 30001
#define REV_PORT 10000

@interface WifiConfigController ()

@end

@implementation WifiConfigController

@synthesize delegate;

- (void)viewDidLoad {
    [super viewDidLoad];
    // Do any additional setup after loading the view from its nib.
}

- (void)didReceiveMemoryWarning {
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}

/*
#pragma mark - Navigation

// In a storyboard-based application, you will often want to do a little preparation before navigation
- (void)prepareForSegue:(UIStoryboardSegue *)segue sender:(id)sender {
    // Get the new view controller using [segue destinationViewController].
    // Pass the selected object to the new view controller.
}
*/

- (IBAction)ssidText:(id)sender {
}

- (IBAction)passwordText:(id)sender {
}

- (IBAction)enterWifiConfig:(id)sender {
//    [delegate didSetWifiConfig:ssid.text pwd:password.text];
    if (ssid.text.length) {
        [self invalidWps];
        [self initWps];
    }else {
        NSLog(@"please enter ssid");
    }
}

- (IBAction)exitWifiConfig:(id)sender {
    [self invalidWps];
    [delegate didFinishWifiConfig];
}

- (void)dealloc {
    [ssid release];
    [password release];
    [status release];
    [super dealloc];
}

#pragma mark - smartlink
- (void)initWps{
    revSocket = [[GCDAsyncUdpSocket alloc] initWithDelegate:self delegateQueue:dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_DEFAULT, 0)];

    sendSocket = [[GCDAsyncUdpSocket alloc] initWithDelegate:self delegateQueue:dispatch_get_main_queue()];

    NSError *error = nil;

    //绑定本地端口
    [revSocket bindToPort:REV_PORT error:&error];
    if (error) {
        NSLog(@"1:%@",error);
        return;
    }

    //启用广播
    [revSocket enableBroadcast:YES error:&error];
    if (error) {
        NSLog(@"2:%@",error);
        return;
    }

    //开始接收数据(不然会收不到数据)
    [revSocket beginReceiving:&error];
    if (error) {
        NSLog(@"3:%@",error);
        return;
    }

    //重复发送广播
    timer = [NSTimer scheduledTimerWithTimeInterval:1 target:self selector:@selector(smartlinkTask) userInfo:nil repeats:YES];

    [timer fire];
    done = false;
    status.text = @"start wps....";
}

- (void)invalidWps {
    if (timer && timer.isValid) {
        [timer invalidate];
        timer = nil;
    }
    if (revSocket) {
        [revSocket close];
        revSocket = nil;
    }
    if (sendSocket) {
        [sendSocket close];
        sendSocket = nil;
    }
    status.text = @"status";
}

- (void)smartlinkEncoder:(NSString *)ssid
                password:(NSString *)pwd
                      ip:(NSString *)ip
{
    payload = [[NSMutableArray alloc] init];
    unsigned int payloadLength = 2 + ssid.length + 1 + pwd.length + 1 + 4 + 1; //head + password + 0 + ssid + 0 + ip + verify
    NSArray *arrayIp = [ip componentsSeparatedByString:@"."];
    unsigned int start;
    NSString *format;
    unsigned int evenMask = 0;
    NSString *dataMask = 0;
    int asciiCode;

    NSLog(@"payload total length %d, ip=%@", payloadLength, ip);
    NSLog(@"arrayIp =%@", arrayIp);

    //head
    [payload addObject:@"239.0.0.0"];

    format = [[NSString alloc] initWithString:[NSString stringWithFormat:@"239.0.170.%d", payloadLength]];
    [payload addObject:format];

    format = [[NSString alloc] initWithString:[NSString stringWithFormat:@"239.1.85.%d", payloadLength-3]];
    [payload addObject:format];

    //ssid, pwd
    start = 2;
    NSString *sp = [[NSString alloc] initWithString:[NSString stringWithFormat:@"%@%d%@%d", pwd, 0, ssid, 0]];
    NSLog(@"sp %@", sp);
    for (int i=0; i < ssid.length + pwd.length +2; i++, start++) {
        evenMask = (start%2 == 0)?170:85;

        dataMask = [[sp substringFromIndex:i] substringToIndex:1];
        if ([dataMask isEqualToString:@"0"]) {
            asciiCode = 0;
        }else {
            asciiCode = [dataMask characterAtIndex:0];
        }
        format = [[NSString alloc] initWithString:[NSString stringWithFormat:@"239.%d.%d.%d", start, evenMask, asciiCode]];
        [payload addObject:format];
    }

    //local ip
    for (int i=0; i < 4; i++, start++) {
        evenMask = (start%2 == 0)?170:85;

        format = [[NSString alloc] initWithString:[NSString stringWithFormat:@"239.%d.%d.%@", start, evenMask, [arrayIp objectAtIndex:i]]];
        [payload addObject:format];
    }

    //verify
    evenMask = (start%2 == 0)?170:85;
    format = [[NSString alloc] initWithString:[NSString stringWithFormat:@"239.%d.%d.%d", start, evenMask, 33]];
    [payload addObject:format];

    NSLog(@"%@", payload);
}

- (void)smartlinkTask
{
    NSString *msg = @"Start wps!";
    NSData * data = [msg dataUsingEncoding:NSUTF8StringEncoding];

    if (done) {
        status.text = @"wps is done!";
        return;
    }

    [revSocket sendData:data toHost:@"255.255.255.255" port:BROADCAST_PORT withTimeout:10 tag:100];

    [self smartlinkEncoder:ssid.text password:password.text ip:[self getIPAddress]];

    if (payload.count) {
        for (int i=0; i<payload.count; i++) {
            [sendSocket sendData:data toHost:payload[i] port:BROADCAST_PORT withTimeout:10 tag:0];
        }
    }
}

#pragma mark - socket delegate
- (void)udpSocket:(GCDAsyncUdpSocket *)sock didReceiveData:(NSData *)data fromAddress:(NSData *)address withFilterContext:(id)filterContext{
    NSString *msg = [[NSString alloc] initWithData:data encoding:NSUTF8StringEncoding];

    NSLog(@"%@",msg);
    if ([msg isEqualToString:@"wificonnected"]) {
        done = true;
    }
}

#pragma mark 获取当前IP
- (NSString *)getIPAddress {
    NSString *address = @"error";
    struct ifaddrs *interfaces = NULL;
    struct ifaddrs *temp_addr = NULL;
    int success = 0;
    // retrieve the current interfaces - returns 0 on success
    success = getifaddrs(&interfaces);
    if (success == 0) {
        // Loop through linked list of interfaces
        temp_addr = interfaces;
        while(temp_addr != NULL) {
            if(temp_addr->ifa_addr->sa_family == AF_INET) {
                // Check if interface is en0 which is the wifi connection on the iPhone
                if([[NSString stringWithUTF8String:temp_addr->ifa_name] isEqualToString:@"en0"]) {
                    // Get NSString from C String
                    address = [NSString stringWithUTF8String:inet_ntoa(((struct sockaddr_in *)temp_addr->ifa_addr)->sin_addr)];
                }
            }
            temp_addr = temp_addr->ifa_next;
        }
    }
    // Free memory
    freeifaddrs(interfaces);
    return address;
}

@end
