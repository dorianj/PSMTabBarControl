//
//  PSMTabBarControlPalette.m
//  PSMTabBarControl
//
//  Created by John Pannell on 12/21/05.
//  Copyright Positive Spin Media 2005 . All rights reserved.
//

#import "PSMTabBarControlPlugin.h"

@implementation PSMTabBarControlPlugin

- (NSArray *)libraryNibNames {
	return [NSArray arrayWithObjects:@"PSMTabBarControlLibrary", nil];
}
- (NSArray *)requiredFrameworks {
	NSBundle *frameworkBundle = [NSBundle bundleWithIdentifier:@"com.positivespinmedia.PSMTabBarControlFramework"];
	return [NSArray arrayWithObject:frameworkBundle];
}
- (NSString *)label {
	return @"PSMTabBarControl";
}

@end