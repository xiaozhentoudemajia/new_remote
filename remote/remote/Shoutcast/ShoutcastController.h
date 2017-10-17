//
//  ShoutcastController.h
//  AcaRemote
//
//  Created by ALI_MAC on 2017/9/21.
//
//

#import <UIKit/UIKit.h>

@protocol ShoutcastDelegate

- (void)didFinishShoutcast;

@end

@interface ShoutcastController : UINavigationController {
    id<ShoutcastDelegate> __unsafe_unretained delegate;
}

@property (nonatomic, assign) id<ShoutcastDelegate> delegate;

@end
