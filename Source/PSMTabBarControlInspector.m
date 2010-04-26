//
//  PSMTabBarControlInspector.m
//  PSMTabBarControl
//
//  Created by John Pannell on 12/21/05.
//  Copyright Positive Spin Media 2005 . All rights reserved.
//

#import "PSMTabBarControlInspector.h"
#import "PSMTabBarControl.h"

#define kPSMStyleTag 0
#define kPSMCanCloseOnlyTabTag 1
#define kPSMHideForSingleTabTag 2
#define kPSMShowAddTabTag 3
#define kPSMMinWidthTag 4
#define kPSMMaxWidthTag 5
#define kPSMOptimumWidthTag 6
#define kPSMSizeToFitTag 7
#define kPSMAutomaticallyAnimates 8
#define kPSMDisableTabClose 9
#define kPSMUseOverflowMenu 10
#define kPSMSelectTabsOnMouseDown 11
#define kPSMAllowsBackgroundTabClosing 12

@implementation PSMTabBarControlInspector

- (id)init {
	self = [super init];
	[NSBundle loadNibNamed:@"PSMTabBarControlInspector" owner:self];
	return self;
}
+ (BOOL)supportsMultipleObjectInspection {
	return NO;
}
- (void)refresh {
	id object = [[self inspectedObjects] objectAtIndex:0];

	if(object != nil) {
		[_stylePopUp selectItemWithTitle:[object styleName]];
		[_canCloseOnlyTab setState:[object canCloseOnlyTab]];
		[_disableTabClose setState:[object disableTabClose]];
		[_hideForSingleTab setState:[object hideForSingleTab]];
		[_showAddTab setState:[object showAddTabButton]];
		[_cellMinWidth setIntegerValue:[object cellMinWidth]];
		[_cellMaxWidth setIntegerValue:[object cellMaxWidth]];
		[_cellOptimumWidth setIntegerValue:[object cellOptimumWidth]];
		[_sizeToFit setState:[object sizeCellsToFit]];
		[_useOverflowMenu setState:[object useOverflowMenu]];
		[_automaticallyAnimates setState:[object automaticallyAnimates]];
		[_selectsTabsOnMouseDown setState:[object selectsTabsOnMouseDown]];
		[_allowsBackgroundTabClosing setState:[object allowsBackgroundTabClosing]];
	}
}
- (void)ok:(id)sender {
	id object = [[self inspectedObjects] objectAtIndex:0];

	if(object != nil) {
		if([sender tag] == kPSMStyleTag) {
			[object setStyleNamed:[sender titleOfSelectedItem]];
		} else if([sender tag] == kPSMCanCloseOnlyTabTag) {
			[object setCanCloseOnlyTab:[sender state]];
		} else if([sender tag] == kPSMHideForSingleTabTag) {
			[object setHideForSingleTab:[sender state]];
		} else if([sender tag] == kPSMShowAddTabTag) {
			[object setShowAddTabButton:[sender state]];
		} else if([sender tag] == kPSMMinWidthTag) {
			if([object cellOptimumWidth] < [sender integerValue]) {
				[object setCellMinWidth:[object cellOptimumWidth]];
				[sender setIntegerValue:[object cellOptimumWidth]];
			} else {
				[object setCellMinWidth:[sender integerValue]];
			}
		} else if([sender tag] == kPSMMaxWidthTag) {
			if([object cellOptimumWidth] > [sender integerValue]) {
				[object setCellMaxWidth:[object cellOptimumWidth]];
				[sender setIntegerValue:[object cellOptimumWidth]];
			} else {
				[object setCellMaxWidth:[sender integerValue]];
			}
		} else if([sender tag] == kPSMOptimumWidthTag) {
			if([object cellMaxWidth] < [sender integerValue]) {
				[object setCellOptimumWidth:[object cellMaxWidth]];
				[sender setIntegerValue:[object cellMaxWidth]];
			} else if([object cellMinWidth] > [sender integerValue]) {
				[object setCellOptimumWidth:[object cellMinWidth]];
				[sender setIntegerValue:[object cellMinWidth]];
			} else {
				[object setCellOptimumWidth:[sender integerValue]];
			}
		} else if([sender tag] == kPSMSizeToFitTag) {
			[object setSizeCellsToFit:[sender state]];
		} else if([sender tag] == kPSMDisableTabClose) {
			[object setDisableTabClose:[sender state]];
		} else if([sender tag] == kPSMUseOverflowMenu) {
			[object setUseOverflowMenu:[sender state]];
		} else if([sender tag] == kPSMAutomaticallyAnimates) {
			[object setAutomaticallyAnimates:[sender state]];
		} else if([sender tag] == kPSMSelectTabsOnMouseDown) {
			[object setSelectsTabsOnMouseDown:[sender state]];
		} else if([sender tag] == kPSMAllowsBackgroundTabClosing) {
			[object setAllowsBackgroundTabClosing:[sender state]];
		}
	}
}

@end;