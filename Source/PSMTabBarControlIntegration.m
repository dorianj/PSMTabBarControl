//
//  PSMTabBarControlInspector.m
//  PSMTabBarControl
//
//  Created by John Pannell on 12/21/05.
//  Copyright Positive Spin Media 2005 . All rights reserved.
//

#import <InterfaceBuilderKit/InterfaceBuilderKit.h>
#import "PSMTabBarControl.h"
#import "PSMTabBarControlInspector.h"


@implementation PSMTabBarControl (PSMTabBarControlIntegration)

- (NSSize)ibMinimumSize {
	return NSMakeSize(50,22);
} 
- (NSSize)ibMaximumSize {
	return NSMakeSize(100000,22);
}
- (void)ibPopulateKeyPaths:(NSMutableDictionary *)keyPaths {
	[super ibPopulateKeyPaths:keyPaths];
	[[keyPaths objectForKey:IBAttributeKeyPaths] addObjectsFromArray:[NSArray array]];
}

- (void)ibPopulateAttributeInspectorClasses:(NSMutableArray *)classes {
	[super ibPopulateAttributeInspectorClasses:classes];
	[classes addObject:[PSMTabBarControlInspector class]];
}

@end