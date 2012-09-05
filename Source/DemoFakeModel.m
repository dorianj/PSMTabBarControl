//
//  FakeModel.m
//  TabBarControl
//
//  Created by John Pannell on 12/19/05.
//  Copyright 2005 Positive Spin Media. All rights reserved.
//

#import "DemoFakeModel.h"


@implementation DemoFakeModel

@synthesize largeImage = _largeImage;
@synthesize icon = _icon;
@synthesize iconName = _iconName;

@synthesize isProcessing = _isProcessing;
@synthesize objectCount = _objectCount;
@synthesize isEdited = _isEdited;

- (id)init {
	if((self = [super init])) {
		_isProcessing = NO;
		_icon = nil;
		_iconName = nil;
        _largeImage = nil;
		_objectCount = 2;
		_isEdited = NO;
	}
	return self;
}

-(void)dealloc {
    
    [_icon release], _icon = nil;
    [_iconName release], _iconName = nil;
    [_largeImage release], _largeImage = nil;

    [super dealloc];
}

@end
