//
//  PSMOverflowPopUpButton.m
//  NetScrape
//
//  Created by John Pannell on 8/4/04.
//  Copyright 2004 Positive Spin Media. All rights reserved.
//

#import "PSMRolloverButton.h"

@implementation PSMRolloverButton

@synthesize usualImage = _usualImage;
@synthesize rolloverImage = _rolloverImage;

- (id)initWithFrame:(NSRect)frameRect {
    self = [super initWithFrame:frameRect];
    if (self) {
    
        [self addObserver:self forKeyPath:@"usualImage" options:NSKeyValueObservingOptionNew | NSKeyValueObservingOptionOld | NSKeyValueObservingOptionInitial context:NULL];

    }
    return self;
}

- (void)dealloc {

    [self removeObserver:self forKeyPath:@"usualImage"];

    [_usualImage release], _usualImage = nil;
    [_rolloverImage release], _rolloverImage = nil;
    
	[super dealloc];
}

// override for rollover effect
- (void)mouseEntered:(NSEvent *)theEvent;
{
	// set rollover image
	[self setImage:_rolloverImage];

	[super mouseEntered:theEvent];
}

- (void)mouseExited:(NSEvent *)theEvent;
{
	// restore usual image
	[self setImage:_usualImage];

	[super mouseExited:theEvent];
}

#pragma mark -
#pragma mark KVO

-(void)observeValueForKeyPath:(NSString *)keyPath ofObject:(id)object change:(NSDictionary *)change context:(void *)context {

    if ([keyPath isEqualToString:@"usualImage"])
        {
        [self setImage:[self usualImage]];
        }
    else
        [super observeValueForKeyPath:keyPath ofObject:object change:change context:context];
}

#pragma mark -
#pragma mark Tracking Area Support

- (void)addTrackingAreasInRect:(NSRect)cellFrame withUserInfo:(NSDictionary *)userInfo mouseLocation:(NSPoint)mouseLocation {

    NSTrackingAreaOptions options = 0;
    BOOL mouseIsInside = NO;
    NSTrackingArea *area = nil;

    // ---- add tracking area for hover effect ----
    
    options = NSTrackingEnabledDuringMouseDrag | NSTrackingMouseEnteredAndExited | NSTrackingActiveAlways;

    mouseIsInside = NSMouseInRect(mouseLocation, cellFrame, [self isFlipped]);
    if (mouseIsInside) {
        options |= NSTrackingAssumeInside;
    }
    
    // We make the view the owner, and it delegates the calls back to the cell after it is properly setup for the corresponding row/column in the outlineview
    area = [[NSTrackingArea alloc] initWithRect:cellFrame options:options owner:self userInfo:userInfo];
    [self addTrackingArea:area];
    [area release], area = nil;
}

-(void)updateTrackingAreas {

    [super updateTrackingAreas];
    
    // remove all tracking rects
    for (NSTrackingArea *area in [self trackingAreas]) {
        // We have to uniquely identify our own tracking areas
        if ([area owner] == self) {
            [self removeTrackingArea:area];
            
            // restore usual image
            [self setImage:_usualImage];
        }
    }

    // recreate tracking areas and tool tip rects
    NSPoint mouseLocation = [self convertPoint:[[self window] convertScreenToBase:[NSEvent mouseLocation]] fromView:nil];
    
    [self addTrackingAreasInRect:[self bounds] withUserInfo:nil mouseLocation:mouseLocation];
}

#pragma mark -
#pragma mark Archiving

- (void)encodeWithCoder:(NSCoder *)aCoder {
	[super encodeWithCoder:aCoder];
	if([aCoder allowsKeyedCoding]) {
		[aCoder encodeObject:_rolloverImage forKey:@"rolloverImage"];
		[aCoder encodeObject:_usualImage forKey:@"usualImage"];
	}
}

- (id)initWithCoder:(NSCoder *)aDecoder {
	self = [super initWithCoder:aDecoder];
	if(self) {
		if([aDecoder allowsKeyedCoding]) {
			_rolloverImage = [[aDecoder decodeObjectForKey:@"rolloverImage"] retain];
			_usualImage = [[aDecoder decodeObjectForKey:@"usualImage"] retain];
		}
	}
	return self;
}

@end
