//
//  PSMTabBarControlDemoAppDelegate.h
//  PSMTabBarControl
//
//  Created by Robert Payne on 4/26/10.
//  Copyright 2010 Zwopple. All rights reserved.
//

#import <Cocoa/Cocoa.h>


@interface DemoAppController : NSObject
#if __MAC_OS_X_VERSION_MIN_REQUIRED >= 1060
	<NSApplicationDelegate>
#endif
{
}

- (IBAction)newWindow:(id)pSender;

@end
