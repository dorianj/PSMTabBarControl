//
//  PSMLiveChatTabStyle.m
//  --------------------
//
//  Created by Keith Blount on 30/04/2006.
//  Copyright 2006 __MyCompanyName__. All rights reserved.
//

#import "PSMLiveChatTabStyle.h"
#import "PSMTabBarCell.h"
#import "PSMTabBarControl.h"
#import "NSBezierPath_AMShading.h"

#define kPSMLiveChatObjectCounterRadius 7.0
#define kPSMLiveChatCounterMinWidth 20

@interface PSMLiveChatTabStyle (Private)
- (void)drawInteriorWithTabCell:(PSMTabBarCell *)cell inView:(NSView*)controlView;
@end

@implementation PSMLiveChatTabStyle

- (NSString *)name {
	return @"LiveChat";
}

#pragma mark -
#pragma mark Creation/Destruction

- (id) init {
	if((self = [super init])) {
		liveChatCloseButton = [[NSImage alloc] initByReferencingFile:[[PSMTabBarControl bundle] pathForImageResource:@"AquaTabClose_Front"]];
		liveChatCloseButtonDown = [[NSImage alloc] initByReferencingFile:[[PSMTabBarControl bundle] pathForImageResource:@"AquaTabClose_Front_Pressed"]];
		liveChatCloseButtonOver = [[NSImage alloc] initByReferencingFile:[[PSMTabBarControl bundle] pathForImageResource:@"AquaTabClose_Front_Rollover"]];

		liveChatCloseDirtyButton = [[NSImage alloc] initByReferencingFile:[[PSMTabBarControl bundle] pathForImageResource:@"AquaTabCloseDirty_Front"]];
		liveChatCloseDirtyButtonDown = [[NSImage alloc] initByReferencingFile:[[PSMTabBarControl bundle] pathForImageResource:@"AquaTabCloseDirty_Front_Pressed"]];
		liveChatCloseDirtyButtonOver = [[NSImage alloc] initByReferencingFile:[[PSMTabBarControl bundle] pathForImageResource:@"AquaTabCloseDirty_Front_Rollover"]];

		_addTabButtonImage = [[NSImage alloc] initByReferencingFile:[[PSMTabBarControl bundle] pathForImageResource:@"AquaTabNew"]];
		_addTabButtonPressedImage = [[NSImage alloc] initByReferencingFile:[[PSMTabBarControl bundle] pathForImageResource:@"AquaTabNewPressed"]];
		_addTabButtonRolloverImage = [[NSImage alloc] initByReferencingFile:[[PSMTabBarControl bundle] pathForImageResource:@"AquaTabNewRollover"]];

		_objectCountStringAttributes = [[NSDictionary alloc] initWithObjectsAndKeys:
										[[NSColor whiteColor] colorWithAlphaComponent:0.85], NSForegroundColorAttributeName,
										[[NSFontManager sharedFontManager] convertFont:[NSFont fontWithName:@"Lucida Grande" size:11.0] toHaveTrait:NSBoldFontMask], NSFontAttributeName,
										nil];
		leftMargin = 5.0;
	}
	return self;
}

- (void)dealloc {
	[liveChatCloseButton release];
	[liveChatCloseButtonDown release];
	[liveChatCloseButtonOver release];
	[liveChatCloseDirtyButton release];
	[liveChatCloseDirtyButtonDown release];
	[liveChatCloseDirtyButtonOver release];
	[_addTabButtonImage release];
	[_addTabButtonPressedImage release];
	[_addTabButtonRolloverImage release];

	[_objectCountStringAttributes release];

	[super dealloc];
}

#pragma mark -
#pragma mark Control Specific

- (void)setLeftMarginForTabBarControl:(CGFloat)margin {
	leftMargin = margin;
}

- (CGFloat)leftMarginForTabBarControl {
	return leftMargin;
}

- (CGFloat)rightMarginForTabBarControl {
	return 24.0f;
}

- (CGFloat)topMarginForTabBarControl {
	return 10.0f;
}

- (void)setOrientation:(PSMTabBarOrientation)value {
}

#pragma mark -
#pragma mark Add Tab Button

- (NSImage *)addTabButtonImage {
	return _addTabButtonImage;
}

- (NSImage *)addTabButtonPressedImage {
	return _addTabButtonPressedImage;
}

- (NSImage *)addTabButtonRolloverImage {
	return _addTabButtonRolloverImage;
}

#pragma mark -
#pragma mark Cell Specific

- (NSRect)dragRectForTabCell:(PSMTabBarCell *)cell orientation:(PSMTabBarOrientation)orientation {
	NSRect dragRect = [cell frame];
	dragRect.size.width++;
	return dragRect;
}

- (NSRect)closeButtonRectForTabCell:(PSMTabBarCell *)cell withFrame:(NSRect)cellFrame {
	if([cell hasCloseButton] == NO) {
		return NSZeroRect;
	}

	NSRect result;
	result.size = [liveChatCloseButton size];
	result.origin.x = cellFrame.origin.x + cellFrame.size.width - result.size.width - MARGIN_X;
	result.origin.y = cellFrame.origin.y + MARGIN_Y + 2.0;

	return result;
}

- (NSRect)iconRectForTabCell:(PSMTabBarCell *)cell {
	NSRect cellFrame = [cell frame];

	if([cell hasIcon] == NO) {
		return NSZeroRect;
	}

	NSRect result;
	result.size = NSMakeSize(kPSMTabBarIconWidth, kPSMTabBarIconWidth);
	result.origin.x = cellFrame.origin.x + MARGIN_X;
	result.origin.y = cellFrame.origin.y + MARGIN_Y;

	return result;
}

- (NSRect)indicatorRectForTabCell:(PSMTabBarCell *)cell {
	NSRect cellFrame = [cell frame];

	if([[cell indicator] isHidden]) {
		return NSZeroRect;
	}

	NSRect result;
	result.size = NSMakeSize(kPSMTabBarIndicatorWidth, kPSMTabBarIndicatorWidth);
	result.origin.x = cellFrame.origin.x + cellFrame.size.width - MARGIN_X - kPSMTabBarIndicatorWidth;
	result.origin.y = cellFrame.origin.y + MARGIN_Y;

	return result;
}

- (NSRect)objectCounterRectForTabCell:(PSMTabBarCell *)cell {
	NSRect cellFrame = [cell frame];

	if([cell count] == 0) {
		return NSZeroRect;
	}

	CGFloat countWidth = [[self attributedObjectCountValueForTabCell:cell] size].width;
	countWidth += (2 * kPSMLiveChatObjectCounterRadius - 6.0);
	if(countWidth < kPSMLiveChatCounterMinWidth) {
		countWidth = kPSMLiveChatCounterMinWidth;
	}

	NSRect result;
	result.size = NSMakeSize(countWidth, 2 * kPSMLiveChatObjectCounterRadius); // temp
	result.origin.x = cellFrame.origin.x + cellFrame.size.width - MARGIN_X - result.size.width;
	result.origin.y = cellFrame.origin.y + MARGIN_Y + 2.0;

	if(![[cell indicator] isHidden]) {
		result.origin.x -= kPSMTabBarIndicatorWidth + kPSMTabBarCellPadding;
	}
	if([cell hasCloseButton] == YES) {
		result.origin.x -= [liveChatCloseButton size].width + kPSMTabBarCellPadding;
	}

	return result;
}


- (CGFloat)minimumWidthOfTabCell:(PSMTabBarCell *)cell {
	CGFloat resultWidth = 0.0;

	// left margin
	resultWidth = MARGIN_X;

	// close button?
	if([cell hasCloseButton] && ![cell isCloseButtonSuppressed]) {
		resultWidth += [liveChatCloseButton size].width + kPSMTabBarCellPadding;
	}

	// icon?
	if([cell hasIcon]) {
		resultWidth += kPSMTabBarIconWidth + kPSMTabBarCellPadding;
	}

	// the label
	resultWidth += kPSMMinimumTitleWidth;

	// object counter?
	if([cell count] > 0) {
		resultWidth += [self objectCounterRectForTabCell:cell].size.width + kPSMTabBarCellPadding;
	}

	// indicator?
	if([[cell indicator] isHidden] == NO) {
		resultWidth += kPSMTabBarCellPadding + kPSMTabBarIndicatorWidth;
	}

	// right margin
	resultWidth += MARGIN_X;

	return ceil(resultWidth);
}

- (CGFloat)desiredWidthOfTabCell:(PSMTabBarCell *)cell {
	CGFloat resultWidth = 0.0;

	// left margin
	resultWidth = MARGIN_X;

	// close button?
	if([cell hasCloseButton] && ![cell isCloseButtonSuppressed]) {
		resultWidth += [liveChatCloseButton size].width + kPSMTabBarCellPadding;
	}

	// icon?
	if([cell hasIcon]) {
		resultWidth += kPSMTabBarIconWidth + kPSMTabBarCellPadding;
	}

	// the label
	resultWidth += [[cell attributedStringValue] size].width;

	// object counter?
	if([cell count] > 0) {
		resultWidth += [self objectCounterRectForTabCell:cell].size.width + kPSMTabBarCellPadding;
	}

	// indicator?
	if([[cell indicator] isHidden] == NO) {
		resultWidth += kPSMTabBarCellPadding + kPSMTabBarIndicatorWidth;
	}

	// right margin
	resultWidth += MARGIN_X;

	return ceil(resultWidth);
}

- (CGFloat)tabCellHeight {
	return kPSMTabBarControlHeight;
}

#pragma mark -
#pragma mark Cell Values

- (NSAttributedString *)attributedObjectCountValueForTabCell:(PSMTabBarCell *)cell {
	NSString *contents = [NSString stringWithFormat:@"%lu", (unsigned long)[cell count]];
	return [[[NSMutableAttributedString alloc] initWithString:contents attributes:_objectCountStringAttributes] autorelease];
}

- (NSAttributedString *)attributedStringValueForTabCell:(PSMTabBarCell *)cell {
	NSMutableAttributedString *attrStr;
	NSString * contents = [cell stringValue];
	attrStr = [[[NSMutableAttributedString alloc] initWithString:contents] autorelease];
	NSRange range = NSMakeRange(0, [contents length]);

	[attrStr addAttribute:NSFontAttributeName value:[NSFont systemFontOfSize:11.0] range:range];

	// Paragraph Style for Truncating Long Text
	static NSMutableParagraphStyle *TruncatingTailParagraphStyle = nil;
	if(!TruncatingTailParagraphStyle) {
		TruncatingTailParagraphStyle = [[[NSParagraphStyle defaultParagraphStyle] mutableCopy] retain];
		[TruncatingTailParagraphStyle setLineBreakMode:NSLineBreakByTruncatingTail];
	}
	[attrStr addAttribute:NSParagraphStyleAttributeName value:TruncatingTailParagraphStyle range:range];

	return attrStr;
}

#pragma mark -
#pragma mark ---- drawing ----

- (void)drawTabCell:(PSMTabBarCell *)cell {
	NSRect cellFrame = [cell frame];

	NSToolbar *toolbar = [[[cell controlView] window] toolbar];
	BOOL showsBaselineSeparator = (toolbar && [toolbar respondsToSelector:@selector(showsBaselineSeparator)] && [toolbar showsBaselineSeparator]);
	if(!showsBaselineSeparator) {
		cellFrame.origin.y += 1.0;
		cellFrame.size.height -= 1.0;
	}

	NSColor * lineColor = nil;
	lineColor = [NSColor colorWithCalibratedWhite:0.576 alpha:1.0];

	BOOL selected = [cell state] == NSOnState;
	if(!showsBaselineSeparator || selected) {
		// selected tab
		NSRect aRect = NSMakeRect(cellFrame.origin.x + 0.5, cellFrame.origin.y - 0.5, cellFrame.size.width, cellFrame.size.height);
		if(selected) {
			aRect.origin.y -= 1.0;
			aRect.size.height += 1.0;
		}

		// frame
		CGFloat radius = MIN(6.0, 0.5f * MIN(NSWidth(aRect), NSHeight(aRect)));
		NSRect rect = NSInsetRect(aRect, radius, radius);

		NSPoint cornerPoint = NSMakePoint(NSMinX(aRect), NSMinY(aRect));
		NSBezierPath* bezier = [NSBezierPath bezierPath];
		[bezier appendBezierPathWithPoints:&cornerPoint count:1];

		[bezier appendBezierPathWithArcWithCenter:NSMakePoint(NSMinX(rect), NSMaxY(rect)) radius:radius startAngle:180.0 endAngle:90.0 clockwise:YES];

		[bezier appendBezierPathWithArcWithCenter:NSMakePoint(NSMaxX(rect), NSMaxY(rect)) radius:radius startAngle:90.0 endAngle:360.0 clockwise:YES];

		cornerPoint = NSMakePoint(NSMaxX(aRect), NSMinY(aRect));
		[bezier appendBezierPathWithPoints:&cornerPoint count:1];

		if([[[tabBar tabView] window] isKeyWindow]) {
			if([cell state] == NSOnState) {
				[bezier linearGradientFillWithStartColor:[NSColor colorWithCalibratedWhite:1.0 alpha:1.0]
				 endColor:[NSColor colorWithCalibratedWhite:0.95 alpha:1.0]];
			} else if([cell isHighlighted]) {
				[bezier linearGradientFillWithStartColor:[NSColor colorWithCalibratedWhite:0.80 alpha:1.0]
				 endColor:[NSColor colorWithCalibratedWhite:0.80 alpha:1.0]];
			}
		} else if([cell state] == NSOnState) {
			[bezier linearGradientFillWithStartColor:[NSColor colorWithCalibratedWhite:1.0 alpha:1.0]
											endColor:[NSColor colorWithCalibratedWhite:0.95 alpha:1.0]];
		}

		[lineColor set];
		[bezier stroke];
	} else {
		// unselected tab
		NSRect aRect = NSMakeRect(cellFrame.origin.x, cellFrame.origin.y, cellFrame.size.width, cellFrame.size.height);
		aRect.origin.y += 0.5;
		aRect.origin.x += 1.5;
		aRect.size.width -= 1;

		aRect.origin.x -= 1;
		aRect.size.width += 1;

		// rollover
		if([cell isHighlighted]) {
			[[NSColor colorWithCalibratedWhite:0.0 alpha:0.1] set];
			NSRectFillUsingOperation(aRect, NSCompositeSourceAtop);
		}

		// frame
		[lineColor set];
		if(!([cell tabState] & PSMTab_RightIsSelectedMask)) {
			[NSBezierPath strokeLineFromPoint:NSMakePoint(aRect.origin.x + aRect.size.width, aRect.origin.y + aRect.size.height - 0.5) toPoint:NSMakePoint(NSMaxX(aRect), NSMaxY(aRect))];
		}
		// Create a thin lighter line next to the dividing line for a bezel effect
		if(!([cell tabState] & PSMTab_RightIsSelectedMask)) {
			[[[NSColor whiteColor] colorWithAlphaComponent:0.5] set];
			[NSBezierPath strokeLineFromPoint:NSMakePoint(NSMaxX(aRect) + 1.0, aRect.origin.y - 0.5)
			 toPoint:NSMakePoint(NSMaxX(aRect) + 1.0, NSMaxY(aRect) - 2.5)];
		}
	}

	[self drawInteriorWithTabCell:cell inView:[cell controlView]];
}


- (void)drawInteriorWithTabCell:(PSMTabBarCell *)cell inView:(NSView*)controlView {
	NSRect cellFrame = [cell frame];
	// label rect
	NSRect labelRect;
	labelRect.origin.x = cellFrame.origin.x + MARGIN_X;
	labelRect.size.width = cellFrame.size.width - (labelRect.origin.x - cellFrame.origin.x) - kPSMTabBarCellPadding;
	NSSize s = [[cell attributedStringValue] size];
	labelRect.origin.y = cellFrame.origin.y + (cellFrame.size.height - s.height) / 2.0;
	labelRect.size.height = s.height;

	// close button
	if([cell hasCloseButton] && ![cell isCloseButtonSuppressed]) {
		NSSize closeButtonSize = NSZeroSize;
		NSRect closeButtonRect = [cell closeButtonRectForFrame:cellFrame];
		NSImage * closeButton = nil;

		closeButton = [cell isEdited] ? liveChatCloseDirtyButton : liveChatCloseButton;

		if([cell closeButtonOver]) {
			closeButton = [cell isEdited] ? liveChatCloseDirtyButtonOver : liveChatCloseButtonOver;
		}
		if([cell closeButtonPressed]) {
			closeButton = [cell isEdited] ? liveChatCloseDirtyButtonDown : liveChatCloseButtonDown;
		}

		closeButtonSize = [closeButton size];
		if([controlView isFlipped]) {
			closeButtonRect.origin.y += closeButtonRect.size.height;
		}

		[closeButton compositeToPoint:closeButtonRect.origin operation:NSCompositeSourceOver fraction:1.0];

		// scoot label over
		labelRect.size.width -= closeButtonSize.width + kPSMTabBarCellPadding;
	}

	// icon
	if([cell hasIcon]) {
		NSRect iconRect = [self iconRectForTabCell:cell];
		NSImage *icon = [[[cell representedObject] identifier] icon];
		if([controlView isFlipped]) {
			iconRect.origin.y += iconRect.size.height;
		}

		// center in available space (in case icon image is smaller than kPSMTabBarIconWidth)
		if([icon size].width < kPSMTabBarIconWidth) {
			iconRect.origin.x += (kPSMTabBarIconWidth - [icon size].width) / 2.0;
		}
		if([icon size].height < kPSMTabBarIconWidth) {
			iconRect.origin.y -= (kPSMTabBarIconWidth - [icon size].height) / 2.0;
		}

		[icon compositeToPoint:iconRect.origin operation:NSCompositeSourceOver fraction:1.0];

		// scoot label over
		labelRect.size.width -= iconRect.size.width + kPSMTabBarCellPadding;
		labelRect.origin.x += iconRect.size.width + kPSMTabBarCellPadding;
	}

	if(![[cell indicator] isHidden]) {
		labelRect.size.width -= (kPSMTabBarIndicatorWidth + kPSMTabBarCellPadding);
	}

	// object counter
	if([cell count] > 0) {
		[[cell countColor] ?: [NSColor colorWithCalibratedWhite:0.3 alpha:0.6] set];
		NSBezierPath *path = [NSBezierPath bezierPath];
		NSRect myRect = [self objectCounterRectForTabCell:cell];
		myRect.origin.y -= 1.0;
		[path moveToPoint:NSMakePoint(myRect.origin.x + kPSMLiveChatObjectCounterRadius, myRect.origin.y)];
		[path lineToPoint:NSMakePoint(myRect.origin.x + myRect.size.width - kPSMLiveChatObjectCounterRadius, myRect.origin.y)];
		[path appendBezierPathWithArcWithCenter:NSMakePoint(myRect.origin.x + myRect.size.width - kPSMLiveChatObjectCounterRadius, myRect.origin.y + kPSMLiveChatObjectCounterRadius) radius:kPSMLiveChatObjectCounterRadius startAngle:270.0 endAngle:90.0];
		[path lineToPoint:NSMakePoint(myRect.origin.x + kPSMLiveChatObjectCounterRadius, myRect.origin.y + myRect.size.height)];
		[path appendBezierPathWithArcWithCenter:NSMakePoint(myRect.origin.x + kPSMLiveChatObjectCounterRadius, myRect.origin.y + kPSMLiveChatObjectCounterRadius) radius:kPSMLiveChatObjectCounterRadius startAngle:90.0 endAngle:270.0];
		[path fill];

		// draw attributed string centered in area
		NSRect counterStringRect;
		NSAttributedString *counterString = [self attributedObjectCountValueForTabCell:cell];
		counterStringRect.size = [counterString size];
		counterStringRect.origin.x = myRect.origin.x + ((myRect.size.width - counterStringRect.size.width) / 2.0) + 0.25;
		counterStringRect.origin.y = myRect.origin.y + ((myRect.size.height - counterStringRect.size.height) / 2.0) + 0.5;
		[counterString drawInRect:counterStringRect];

		labelRect.size.width -= myRect.size.width + kPSMTabBarCellPadding;
	}

	// label
	[[cell attributedStringValue] drawInRect:labelRect];
}

- (void)drawBackgroundInRect:(NSRect)rect {
	//Draw for our whole bounds; it'll be automatically clipped to fit the appropriate drawing area
	rect = [tabBar bounds];

	if([[[tabBar tabView] window] isKeyWindow]) {
		NSRect gradientRect = rect;
		gradientRect.origin.y += 1.0;
		NSBezierPath *path = [NSBezierPath bezierPathWithRect:gradientRect];
		[path linearGradientFillWithStartColor:[NSColor colorWithCalibratedWhite:0.75 alpha:1.0]
									  endColor:[NSColor colorWithCalibratedWhite:0.75 alpha:0.0]];
	}
	[[NSColor colorWithCalibratedWhite:0.576 alpha:1.0] set];
	[NSBezierPath strokeLineFromPoint:NSMakePoint(rect.origin.x, NSMinY(rect) + 0.5)
							  toPoint:NSMakePoint(NSMaxX(rect), NSMinY(rect) + 0.5)];
}

- (void)drawTabBar:(PSMTabBarControl *)bar inRect:(NSRect)rect {
	tabBar = bar;
	[self drawBackgroundInRect:rect];

	// no tab view == not connected
	if(![bar tabView]) {
		NSRect labelRect = rect;
		labelRect.size.height -= 4.0;
		labelRect.origin.y += 4.0;
		NSMutableAttributedString *attrStr;
		NSString *contents = @"PSMTabBarControl";
		attrStr = [[[NSMutableAttributedString alloc] initWithString:contents] autorelease];
		NSRange range = NSMakeRange(0, [contents length]);
		[attrStr addAttribute:NSFontAttributeName value:[NSFont systemFontOfSize:11.0] range:range];
		NSMutableParagraphStyle *centeredParagraphStyle = nil;
		if(!centeredParagraphStyle) {
			centeredParagraphStyle = [[[NSParagraphStyle defaultParagraphStyle] mutableCopy] retain];
			[centeredParagraphStyle setAlignment:NSCenterTextAlignment];
		}
		[attrStr addAttribute:NSParagraphStyleAttributeName value:centeredParagraphStyle range:range];
		[attrStr drawInRect:labelRect];
		return;
	}

	// draw cells
	NSEnumerator *e = [[bar cells] objectEnumerator];
	PSMTabBarCell *cell;
	while((cell = [e nextObject])) {
		if([bar isAnimating] || (![cell isInOverflowMenu] && NSIntersectsRect([cell frame], rect))) {
			[cell drawWithFrame:[cell frame] inView:bar];
		}
	}
}

#pragma mark -
#pragma mark Archiving

- (void)encodeWithCoder:(NSCoder *)aCoder {
	// ... do not encode anything
}

- (id)initWithCoder:(NSCoder *)aDecoder {
	// ... do not read anything
	return [self init];
}

@end
