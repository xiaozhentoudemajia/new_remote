//
//  AppDelegate.m
//  remote
//
//  Created by 一枕小窗浓睡 on 2017/10/16.
//  Copyright © 2017年 一枕小窗浓睡. All rights reserved.
//

#import "AppDelegate.h"
#import "RemoteHDViewController.h"
#import "PreferencesManager.h"
#import "SynthesizeSingleton.h"
#import "DDLog.h"
#import "DDFileLogger.h"
#import "DDTTYLogger.h"
#import "CustomHTTPProtocol.h"

@interface AppDelegate ()

@end

@implementation AppDelegate


- (BOOL)application:(UIApplication *)application didFinishLaunchingWithOptions:(NSDictionary *)launchOptions {
    // Override point for customization after application launch.
    self.window = [[UIWindow alloc]initWithFrame:[[UIScreen mainScreen]bounds]];

    RemoteHDViewController *vc = [[RemoteHDViewController alloc]init];
    self.window.rootViewController = vc;

    self.window.backgroundColor = [UIColor whiteColor];
    [self.window makeKeyAndVisible];

    static const int ddLogLevel = LOG_LEVEL_VERBOSE;//定义日志级别
    [DDLog addLogger:[DDTTYLogger sharedInstance]];// 初始化DDLog日志输出

    //保持一周的文件日志
    DDFileLogger *fileLogger = [[DDFileLogger alloc] init];
    fileLogger.rollingFrequency = 60 * 60 * 24; // 24 hour rolling
    fileLogger.logFileManager.maximumNumberOfLogFiles = 7;
    [DDLog addLogger:fileLogger];

    [NSURLProtocol registerClass:[CustomHTTPProtocol class]];

    return YES;
}


- (void)applicationWillResignActive:(UIApplication *)application {
    // Sent when the application is about to move from active to inactive state. This can occur for certain types of temporary interruptions (such as an incoming phone call or SMS message) or when the user quits the application and it begins the transition to the background state.
    // Use this method to pause ongoing tasks, disable timers, and invalidate graphics rendering callbacks. Games should use this method to pause the game.
}


- (void)applicationDidEnterBackground:(UIApplication *)application {
    // Use this method to release shared resources, save user data, invalidate timers, and store enough application state information to restore your application to its current state in case it is terminated later.
    // If your application supports background execution, this method is called instead of applicationWillTerminate: when the user quits.
}


- (void)applicationWillEnterForeground:(UIApplication *)application {
    // Called as part of the transition from the background to the active state; here you can undo many of the changes made on entering the background.
}


- (void)applicationDidBecomeActive:(UIApplication *)application {
    // Restart any tasks that were paused (or not yet started) while the application was inactive. If the application was previously in the background, optionally refresh the user interface.
}


- (void)applicationWillTerminate:(UIApplication *)application {
    // Called when the application is about to terminate. Save data if appropriate. See also applicationDidEnterBackground:.
}


@end
