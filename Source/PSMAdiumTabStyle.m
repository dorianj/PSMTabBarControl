//
//  PSMAdiumTabStyle.m
//  PSMTabBarControl
//
//  Created by Kent Sutherland on 5/26/06.
//  Copyright 2006 Kent Sutherland. All rights reserved.
//

#import "PSMAdiumTabStyle.h"
#import "PSMTabBarCell.h"
#import "PSMTabBarControl.h"
#import "NSBezierPath_AMShading.h"

// #define Adium_CellPadding 2
#define Adium_MARGIN_X 4
#define kPSMAdiumCounterPadding 3.0

@interface PSMTabBarCell(SharedPrivates)

- (void)_drawIconWithFrame:(NSRect)frame inTabBarControl:(PSMTabBarControl *)tabBarControl;
- (void)_drawCloseButtonWithFrame:(NSRect)frame inTabBarControl:(PSMTabBarControl *)tabBarControl;
- (void)_drawObjectCounterWithFrame:(NSRect)frame inTabBarControl:(PSMTabBarControl *)tabBarControl;

@end

@implementation PSMAdiumTabStyle

- (NSString *)name {
	return @"Adium";
}

#pragma mark -
#pragma mark Creation/Destruction

- (id)init {
	if((self = [super init])) {
		[self loadImages];
		_drawsUnified = NO;
		_drawsRight = NO;

		_objectCountStringAttributes = [[NSDictionary alloc] initWithObjectsAndKeys:[[NSFontManager sharedFontManager] convertFont:[NSFont fontWithName:@"Helvetica" size:11.0] toHaveTrait:NSBoldFontMask], NSFontAttributeName,
										[[NSColor whiteColor] colorWithAlphaComponent:0.85], NSForegroundColorAttributeName,
										nil, nil];
	}
	return self;
}

- (void)loadImages {
	_closeButton = [[NSImage alloc] initByReferencingFile:[[PSMTabBarControl bundle] pathForImageResource:@"AquaTabClose_Front"]];
	_closeButtonDown = [[NSImage alloc] initByReferencingFile:[[PSMTabBarControl bundle] pathForImageResource:@"AquaTabClose_Front_Pressed"]];
	_closeButtonOver = [[NSImage alloc] initByReferencingFile:[[PSMTabBarControl bundle] pathForImageResource:@"AquaTabClose_Front_Rollover"]];

	_closeDirtyButton = [[NSImage alloc] initByReferencingFile:[[PSMTabBarControl bundle] pathForImageResource:@"AquaTabCloseDirty_Front"]];
	_closeDirtyButtonDown = [[NSImage alloc] initByReferencingFile:[[PSMTabBarControl bundle] pathForImageResource:@"AquaTabCloseDirty_Front_Pressed"]];
	_closeDirtyButtonOver = [[NSImage alloc] initByReferencingFile:[[PSMTabBarControl bundle] pathForImageResource:@"AquaTabCloseDirty_Front_Rollover"]];

	_addTabButtonImage = [[NSImage alloc] initByReferencingFile:[[PSMTabBarControl bundle] pathForImageResource:@"AquaTabNew"]];
	_addTabButtonPressedImage = [[NSImage alloc] initByReferencingFile:[[PSMTabBarControl bundle] pathForImageResource:@"AquaTabNewPressed"]];
	_addTabButtonRolloverImage = [[NSImage alloc] initByReferencingFile:[[PSMTabBarControl bundle] pathForImageResource:@"AquaTabNewRollover"]];

	_gradientImage = [[NSImage alloc] initByReferencingFile:[[PSMTabBarControl bundle] pathForImageResource:@"AdiumGradient"]];
}

- (void)dealloc {
	[_closeButton release];
	[_closeButtonDown release];
	[_closeButtonOver release];

	[_closeDirtyButton release];
	[_closeDirtyButtonDown release];
	[_closeDirtyButtonOver release];

	[_addTabButtonImage release];
	[_addTabButtonPressedImage release];
	[_addTabButtonRolloverImage release];

	[_gradientImage release];

	[_objectCountStringAttributes release];

	[super dealloc];
}

#pragma mark -
#pragma mark Drawing Style Accessors

- (BOOL)drawsUnified {
	return _drawsUnified;
}

- (void)setDrawsUnified:(BOOL)value {
	_drawsUnified = value;
}

- (BOOL)drawsRight {
	return _drawsRight;
}

- (void)setDrawsRight:(BOOL)value {
	_drawsRight = value;
}

#pragma mark -
#pragma mark Control Specific

- (CGFloat)leftMarginForTabBarControl {
	return 3.0f;
}

- (CGFloat)rightMarginForTabBarControl {
	return 24.0f;
}

- (CGFloat)topMarginForTabBarControl {
	return 10.0f;
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
#pragma mark Drag Support

- (NSRect)dragRectForTabCell:(PSMTabBarCell *)cell orientation:(PSMTabBarOrientation)tabOrientation {
	NSRect dragRect = [cell frame];

	if([cell tabState] & PSMTab_SelectedMask) {
		if(tabOrientation == PSMTabBarHorizontalOrientation) {
			dragRect.size.width++;
			dragRect.size.height -= 2.0;
		}
	}

	return dragRect;
}

#pragma mark -
#pragma mark Providing Images

- (NSImage *)closeButtonImageOfType:(PSMCloseButtonImageType)type forTabCell:(PSMTabBarCell *)cell
{
    switch (type) {
        case PSMCloseButtonImageTypeStandard:
            return _closeButton;
        case PSMCloseButtonImageTypeRollover:
            return _closeButtonOver;
        case PSMCloseButtonImageTypePressed:
            return _closeButtonDown;
            
        case PSMCloseButtonImageTypeDirty:
            return _closeDirtyButton;
        case PSMCloseButtonImageTypeDirtyRollover:
            return _closeDirtyButtonOver;
        case PSMCloseButtonImageTypeDirtyPressed:
            return _closeDirtyButtonDown;
            
        default:
            break;
    }
    
}

#pragma mark -
#pragma mark Determining Cell Size

- (CGFloat)heightOfTabCellsForTabBarControl:(PSMTabBarControl *)tabBarControl {
    PSMTabBarOrientation orientation = [tabBarControl orientation];
	return((orientation == PSMTabBarHorizontalOrientation) ? kPSMTabBarControlHeight : kPSMTabBarControlSourceListHeight);
}

- (NSRect)drawingRectForBounds:(NSRect)theRect ofTabCell:(PSMTabBarCell *)cell {
    NSRect resultRect;

    if ([(PSMTabBarControl *)[cell controlView] orientation] == PSMTabBarHorizontalOrientation && [cell state] == NSOnState) {
        resultRect = NSInsetRect(theRect,Adium_MARGIN_X,0.0);
        resultRect.origin.y += 1;
        resultRect.size.height -= MARGIN_Y + 2;
    } else {
        resultRect = NSInsetRect(theRect, Adium_MARGIN_X, MARGIN_Y);
        resultRect.size.height -= 1;
    }
    
    return resultRect;
}

- (NSRect)closeButtonRectForBounds:(NSRect)theRect ofTabCell:(PSMTabBarCell *)cell {

    if ([cell shouldDrawCloseButton] == NO) {
        return NSZeroRect;
    }

    PSMTabBarControl *tabBarControl = [cell controlView];
    PSMTabBarOrientation orientation = [tabBarControl orientation];
        
    // ask style for image
    NSImage *image = [cell closeButtonImageOfType:PSMCloseButtonImageTypeStandard];
    if (!image)
        return NSZeroRect;
    
    // calculate rect
    NSRect drawingRect = [cell drawingRectForBounds:theRect];
        
    NSSize imageSize = [image size];
    
    NSSize scaledImageSize = [cell scaleImageWithSize:imageSize toFitInSize:NSMakeSize(imageSize.width, drawingRect.size.height) scalingType:NSImageScaleProportionallyDown];

    NSRect result;
    if (orientation == PSMTabBarHorizontalOrientation) {
        result = NSMakeRect(drawingRect.origin.x, drawingRect.origin.y, scaledImageSize.width, scaledImageSize.height);    
    } else {
    
        NSRect constrainedDrawingRect = drawingRect;

        NSRect indicatorRect = [cell indicatorRectForBounds:theRect];
        if (!NSEqualRects(indicatorRect, NSZeroRect))
            {
            constrainedDrawingRect.size.width -= NSWidth(indicatorRect) + kPSMTabBarCellPadding;
            }
    
        result = NSMakeRect(NSMaxX(constrainedDrawingRect)-scaledImageSize.width-Adium_MARGIN_X, constrainedDrawingRect.origin.y, scaledImageSize.width, scaledImageSize.height);
    }

    if(scaledImageSize.height < drawingRect.size.height) {
        result.origin.y += ceil((drawingRect.size.height - scaledImageSize.height) / 2.0);
    }

    return NSIntegralRect(result);
}

- (NSRect)iconRectForBounds:(NSRect)theRect ofTabCell:(PSMTabBarCell *)cell {
    
    if (![cell hasIcon])
        return NSZeroRect;
    
    NSImage *icon = [[(NSTabViewItem*)[cell representedObject] identifier] icon];
    if (!icon)
        return NSZeroRect;

    PSMTabBarControl *tabBarControl = [cell controlView];
    PSMTabBarOrientation orientation = [tabBarControl orientation];
    
    if ([cell hasLargeImage] && orientation == PSMTabBarVerticalOrientation)
        return NSZeroRect;

    // calculate rect
    NSRect drawingRect = [cell drawingRectForBounds:theRect];
                
    NSSize iconSize = [icon size];
    
    NSSize scaledIconSize = [cell scaleImageWithSize:iconSize toFitInSize:NSMakeSize(iconSize.width, drawingRect.size.height) scalingType:NSImageScaleProportionallyDown];

    NSRect result;
    if (orientation == PSMTabBarHorizontalOrientation) {
        {
        result = NSMakeRect(drawingRect.origin.x, drawingRect.origin.y, scaledIconSize.width, scaledIconSize.height);
        }
    } else {
        result = NSMakeRect(drawingRect.origin.x, drawingRect.origin.y, scaledIconSize.width, scaledIconSize.height);
    }
    
    // center in available space (in case icon image is smaller than kPSMTabBarIconWidth)
    if(scaledIconSize.width < kPSMTabBarIconWidth) {
        result.origin.x += ceil((kPSMTabBarIconWidth - scaledIconSize.width) / 2.0);
    }

    if(scaledIconSize.height < kPSMTabBarIconWidth) {
        result.origin.y -= ceil((kPSMTabBarIconWidth - scaledIconSize.height) / 2.0 - 0.5);
    }

    return NSIntegralRect(result);    
    
}

- (NSRect)titleRectForBounds:(NSRect)theRect ofTabCell:(PSMTabBarCell *)cell {

    PSMTabBarControl *tabBarControl = [cell controlView];
    PSMTabBarOrientation orientation = [tabBarControl orientation];
        
    NSRect drawingRect = [cell drawingRectForBounds:theRect];

    NSRect constrainedDrawingRect = drawingRect;
        
    NSRect indicatorRect = [cell indicatorRectForBounds:theRect];
    if (!NSEqualRects(indicatorRect, NSZeroRect)) {
        constrainedDrawingRect.size.width -= NSWidth(indicatorRect) + kPSMTabBarCellPadding;
    }
        
    NSRect largeImageRect = [cell largeImageRectForBounds:theRect];
    if (!NSEqualRects(largeImageRect, NSZeroRect)) {
        constrainedDrawingRect.origin.x += NSWidth(largeImageRect) + kPSMTabBarCellPadding;
        constrainedDrawingRect.size.width -= NSWidth(largeImageRect) + kPSMTabBarCellPadding;
    }

    if (orientation == PSMTabBarHorizontalOrientation) {

        NSRect closeButtonRect = [cell closeButtonRectForBounds:theRect];
        NSRect iconRect = [cell iconRectForBounds:theRect];
    
        if (!NSEqualRects(closeButtonRect, NSZeroRect) || !NSEqualRects(iconRect, NSZeroRect)) {
            constrainedDrawingRect.origin.x += MAX(NSWidth(closeButtonRect),NSWidth(iconRect)) + kPSMTabBarCellPadding;
            constrainedDrawingRect.size.width -= MAX(NSWidth(closeButtonRect),NSWidth(iconRect)) + kPSMTabBarCellPadding;
        }
        
        NSRect counterBadgeRect = [cell objectCounterRectForBounds:theRect];
        if (!NSEqualRects(counterBadgeRect, NSZeroRect)) {
            constrainedDrawingRect.size.width -= NSWidth(counterBadgeRect) + kPSMTabBarCellPadding;
        }
    } else {
    
        if ([cell hasIcon] && ![cell hasLargeImage]) {
            NSRect iconRect = [cell iconRectForBounds:theRect];
            if (!NSEqualRects(iconRect, NSZeroRect) || !NSEqualRects(iconRect, NSZeroRect)) {
                constrainedDrawingRect.origin.x += NSWidth(iconRect) + kPSMTabBarCellPadding;
                constrainedDrawingRect.size.width -= NSWidth(iconRect) + kPSMTabBarCellPadding;
                }
        }
    
        NSRect closeButtonRect = [cell closeButtonRectForBounds:theRect];
        NSRect counterBadgeRect = [cell objectCounterRectForBounds:theRect];

        if (!NSEqualRects(closeButtonRect, NSZeroRect) || !NSEqualRects(counterBadgeRect, NSZeroRect)) {
            constrainedDrawingRect.size.width -= MAX(NSWidth(closeButtonRect),NSWidth(counterBadgeRect)) + kPSMTabBarCellPadding;
        }    
    }

    NSAttributedString *attrString = [cell attributedStringValue];
    if ([attrString length] == 0)
        return NSZeroRect;
        
    NSSize stringSize = [attrString size];
    
    NSRect result = NSMakeRect(constrainedDrawingRect.origin.x, drawingRect.origin.y+ceil((drawingRect.size.height-stringSize.height)/2), constrainedDrawingRect.size.width, stringSize.height);
                    
    return NSIntegralRect(result);
}

- (NSRect)indicatorRectForBounds:(NSRect)theRect ofTabCell:(PSMTabBarCell *)cell {

    if([[cell indicator] isHidden]) {
        return NSZeroRect;
    }
    
    // calculate rect
    NSRect drawingRect = [cell drawingRectForBounds:theRect];
        
    NSSize indicatorSize = NSMakeSize(kPSMTabBarIndicatorWidth, kPSMTabBarIndicatorWidth);
    
    NSRect result = NSMakeRect(NSMaxX(drawingRect)-indicatorSize.width,NSMidY(drawingRect)-ceil(indicatorSize.height/2),indicatorSize.width,indicatorSize.height);
    
    return NSIntegralRect(result);
}

- (NSRect)objectCounterRectForBounds:(NSRect)theRect ofTabCell:(PSMTabBarCell *)cell {

    if([cell count] == 0) {
        return NSZeroRect;
    }

    NSRect drawingRect = [cell drawingRectForBounds:theRect];

    NSRect constrainedDrawingRect = drawingRect;

    NSRect indicatorRect = [cell indicatorRectForBounds:theRect];
    if (!NSEqualRects(indicatorRect, NSZeroRect))
        {
        constrainedDrawingRect.size.width -= NSWidth(indicatorRect) + kPSMTabBarCellPadding;
        }
            
    NSSize counterBadgeSize = [cell objectCounterSize];
    
    // calculate rect
    NSRect result;
    result.size = counterBadgeSize; // temp
    result.origin.x = NSMaxX(constrainedDrawingRect)-counterBadgeSize.width;
    result.origin.y = ceil(constrainedDrawingRect.origin.y+(constrainedDrawingRect.size.height-result.size.height)/2);
                
    return NSIntegralRect(result);
}


#pragma mark -
#pragma mark Cell Values

- (NSAttributedString *)attributedObjectCountValueForTabCell:(PSMTabBarCell *)cell {
	NSString *contents = [NSString stringWithFormat:@"%lu", (unsigned long)[cell count]];
	return [[[NSMutableAttributedString alloc] initWithString:contents attributes:_objectCountStringAttributes] autorelease];
}

- (NSAttributedString *)attributedStringValueForTabCell:(PSMTabBarCell *)cell {
	NSMutableAttributedString *attrStr;
	NSString *contents = [cell stringValue];
	attrStr = [[[NSMutableAttributedString alloc] initWithString:contents] autorelease];
	NSRange range = NSMakeRange(0, [contents length]);

	// Add font attribute
	[attrStr addAttribute:NSFontAttributeName value:[NSFont systemFontOfSize:11.0] range:range];
	[attrStr addAttribute:NSForegroundColorAttributeName value:[NSColor controlTextColor] range:range];

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
#pragma mark Cell Drawing

- (void)drawBezelOfTabBarControl:(PSMTabBarControl *)tabBarControl inRect:(NSRect)rect {

	//Draw for our whole bounds; it'll be automatically clipped to fit the appropriate drawing area
	rect = [tabBarControl bounds];

    PSMTabBarOrientation orientation = [tabBarControl orientation];

	switch(orientation) {
	case PSMTabBarHorizontalOrientation :
		if(_drawsUnified && [[[tabBarControl tabView] window] isKeyWindow]) {
			if([[[tabBarControl tabView] window] isKeyWindow]) {
				NSBezierPath *backgroundPath = [NSBezierPath bezierPathWithRect:rect];
				[backgroundPath linearGradientFillWithStartColor:[NSColor colorWithCalibratedWhite:0.835 alpha:1.0]
				 endColor:[NSColor colorWithCalibratedWhite:0.843 alpha:1.0]];
			} else {
				[[NSColor windowBackgroundColor] set];
				NSRectFill(rect);
			}
		} else {
			[[NSColor colorWithCalibratedWhite:0.85 alpha:0.6] set];
			[NSBezierPath fillRect:rect];
		}
		break;

	case PSMTabBarVerticalOrientation:
		//This is the Mail.app source list background color... which differs from the iTunes one.
		[[NSColor colorWithCalibratedRed:.9059
		  green:.9294
		  blue:.9647
		  alpha:1.0] set];
		NSRectFill(rect);
		break;
	}

	//Draw the border and shadow around the tab bar itself
	[NSGraphicsContext saveGraphicsState];
	[[NSGraphicsContext currentContext] setShouldAntialias:NO];

	NSShadow *shadow = [[NSShadow alloc] init];
	[shadow setShadowBlurRadius:2];
	[shadow setShadowColor:[NSColor colorWithCalibratedWhite:0.6 alpha:1.0]];

	[[NSColor grayColor] set];

	NSBezierPath *path = [NSBezierPath bezierPath];
	[path setLineWidth:1.0];

	switch(orientation) {
	case PSMTabBarHorizontalOrientation:
	{
		rect.origin.y++;
		[path moveToPoint:NSMakePoint(rect.origin.x, rect.origin.y)];
		[path lineToPoint:NSMakePoint(rect.origin.x + rect.size.width, rect.origin.y)];
		[shadow setShadowOffset:NSMakeSize(1.5, -1.5)];

		[shadow set];
		[path stroke];

		break;
	}

	case PSMTabBarVerticalOrientation:
	{
		NSPoint startPoint, endPoint;
		NSSize shadowOffset;

		//Draw vertical shadow
		if(_drawsRight) {
			startPoint = NSMakePoint(NSMinX(rect), NSMinY(rect));
			endPoint = NSMakePoint(NSMinX(rect), NSMaxY(rect));
			shadowOffset = NSMakeSize(1.5, -1.5);
		} else {
			startPoint = NSMakePoint(NSMaxX(rect) - 1, NSMinY(rect));
			endPoint = NSMakePoint(NSMaxX(rect) - 1, NSMaxY(rect));
			shadowOffset = NSMakeSize(-1.5, -1.5);
		}

		[path moveToPoint:startPoint];
		[path lineToPoint:endPoint];
		[shadow setShadowOffset:shadowOffset];

		[shadow set];
		[path stroke];

		[path removeAllPoints];

		//Draw top horizontal shadow
		startPoint = NSMakePoint(NSMinX(rect), NSMinY(rect));
		endPoint = NSMakePoint(NSMaxX(rect), NSMinY(rect));
		shadowOffset = NSMakeSize(0, -1.5);

		[path moveToPoint:startPoint];
		[path lineToPoint:endPoint];
		[shadow setShadowOffset:shadowOffset];

		[shadow set];
		[path stroke];

		break;
	}
	}

	[shadow release];
	[NSGraphicsContext restoreGraphicsState];
}

- (void)drawInteriorOfTabBarControl:(PSMTabBarControl *)tabBarControl inRect:(NSRect)rect {

	// no tab view == not connected
	if(![tabBarControl tabView]) {
		NSRect labelRect = rect;
		labelRect.size.height -= 4.0;
		labelRect.origin.y += 4.0;
		NSMutableAttributedString *attrStr;
		NSString *contents = @"PSMTabBarControl";
		attrStr = [[[NSMutableAttributedString alloc] initWithString:contents] autorelease];
		NSRange range = NSMakeRange(0, [contents length]);
		[attrStr addAttribute:NSFontAttributeName value:[NSFont systemFontOfSize:11.0] range:range];
		NSMutableParagraphStyle *centeredParagraphStyle = [[NSParagraphStyle defaultParagraphStyle] mutableCopy];
        [centeredParagraphStyle setAlignment:NSCenterTextAlignment];

		[attrStr addAttribute:NSParagraphStyleAttributeName value:centeredParagraphStyle range:range];
		[attrStr drawInRect:labelRect];
        
        [centeredParagraphStyle release];
		return;
	}

	// draw cells
	NSEnumerator *e = [[tabBarControl cells] objectEnumerator];
	PSMTabBarCell *cell;
	while((cell = [e nextObject])) {
		if([tabBarControl isAnimating] || (![cell isInOverflowMenu] && NSIntersectsRect([cell frame], rect))) {
			[cell drawWithFrame:[cell frame] inTabBarControl:tabBarControl];
		}
	}
}

- (void)drawBezelOfTabCell:(PSMTabBarCell *)cell withFrame:(NSRect)frame inTabBarControl:(PSMTabBarControl *)tabBarControl {

    NSRect cellFrame = [cell frame];
	NSColor *lineColor = nil;
	NSBezierPath *bezier = [NSBezierPath bezierPath];
	lineColor = [NSColor grayColor];
    
    PSMTabBarOrientation orientation = [tabBarControl orientation];

	[bezier setLineWidth:1.0];

	//disable antialiasing of bezier paths
	[NSGraphicsContext saveGraphicsState];
	[[NSGraphicsContext currentContext] setShouldAntialias:NO];

	NSShadow *shadow = [[NSShadow alloc] init];
	[shadow setShadowOffset:NSMakeSize(-1.5, -1.5)];
	[shadow setShadowBlurRadius:2];
	[shadow setShadowColor:[NSColor colorWithCalibratedWhite:0.6 alpha:1.0]];

	if([cell state] == NSOnState) {
		// selected tab
		if(orientation == PSMTabBarHorizontalOrientation) {
			NSRect aRect = NSMakeRect(cellFrame.origin.x, cellFrame.origin.y, NSWidth(cellFrame), cellFrame.size.height - 2.5);

			// background
			if(_drawsUnified) {
				if([[[tabBarControl tabView] window] isKeyWindow]) {
					NSBezierPath *path = [NSBezierPath bezierPathWithRect:aRect];
					[path linearGradientFillWithStartColor:[NSColor colorWithCalibratedWhite:0.835 alpha:1.0]
					 endColor:[NSColor colorWithCalibratedWhite:0.843 alpha:1.0]];
				} else {
					[[NSColor windowBackgroundColor] set];
					NSRectFill(aRect);
				}
			} else {
				[_gradientImage drawInRect:NSMakeRect(NSMinX(aRect), NSMinY(aRect), NSWidth(aRect), NSHeight(aRect)) fromRect:NSMakeRect(0, 0, [_gradientImage size].width, [_gradientImage size].height) operation:NSCompositeSourceOver fraction:1.0];
			}

			// frame
			[lineColor set];
			[bezier setLineWidth:1.0];
			[bezier moveToPoint:NSMakePoint(aRect.origin.x, aRect.origin.y)];
			[bezier lineToPoint:NSMakePoint(aRect.origin.x, aRect.origin.y + aRect.size.height)];

			[shadow setShadowOffset:NSMakeSize(-1.5, -1.5)];
			[shadow set];
			[bezier stroke];

			bezier = [NSBezierPath bezierPath];
			[bezier setLineWidth:1.0];
			[bezier moveToPoint:NSMakePoint(NSMinX(aRect), NSMaxY(aRect))];
			[bezier lineToPoint:NSMakePoint(NSMaxX(aRect), NSMaxY(aRect))];
			[bezier lineToPoint:NSMakePoint(NSMaxX(aRect), NSMinY(aRect))];

			if([[cell controlView] frame].size.height < 2) {
				// special case of hidden control; need line across top of cell
				[bezier moveToPoint:NSMakePoint(aRect.origin.x, aRect.origin.y + 0.5)];
				[bezier lineToPoint:NSMakePoint(aRect.origin.x + aRect.size.width, aRect.origin.y + 0.5)];
			}

			[shadow setShadowOffset:NSMakeSize(1.5, -1.5)];
			[shadow set];
			[bezier stroke];
		} else {
			NSRect aRect;

			if(_drawsRight) {
				aRect = NSMakeRect(cellFrame.origin.x - 1, cellFrame.origin.y, cellFrame.size.width - 3, cellFrame.size.height);
			} else {
				aRect = NSMakeRect(cellFrame.origin.x + 2, cellFrame.origin.y, cellFrame.size.width - 2, cellFrame.size.height);
			}

			// background
			if(_drawsUnified) {
				if([[[tabBarControl tabView] window] isKeyWindow]) {
					NSBezierPath *path = [NSBezierPath bezierPathWithRect:aRect];
					[path linearGradientFillWithStartColor:[NSColor colorWithCalibratedWhite:0.835 alpha:1.0]
					 endColor:[NSColor colorWithCalibratedWhite:0.843 alpha:1.0]];
				} else {
					[[NSColor windowBackgroundColor] set];
					NSRectFill(aRect);
				}
			} else {
				NSBezierPath *path = [NSBezierPath bezierPathWithRect:aRect];
				if(_drawsRight) {
					[path linearVerticalGradientFillWithStartColor:[NSColor colorWithCalibratedWhite:0.92 alpha:1.0]
					 endColor:[NSColor colorWithCalibratedWhite:0.98 alpha:1.0]];
				} else {
					[path linearVerticalGradientFillWithStartColor:[NSColor colorWithCalibratedWhite:0.98 alpha:1.0]
					 endColor:[NSColor colorWithCalibratedWhite:0.92 alpha:1.0]];
				}
			}

			// frame
			//top line
			[lineColor set];
			[bezier setLineWidth:1.0];
			[bezier moveToPoint:NSMakePoint(NSMinX(aRect), NSMinY(aRect))];
			[bezier lineToPoint:NSMakePoint(NSMaxX(aRect), NSMinY(aRect))];
			[bezier stroke];

			//outer edge and bottom lines
			bezier = [NSBezierPath bezierPath];
			[bezier setLineWidth:1.0];
			if(_drawsRight) {
				//Right
				[bezier moveToPoint:NSMakePoint(NSMaxX(aRect), NSMinY(aRect))];
				[bezier lineToPoint:NSMakePoint(NSMaxX(aRect), NSMaxY(aRect))];
				//Bottom
				[bezier lineToPoint:NSMakePoint(NSMinX(aRect), NSMaxY(aRect))];
			} else {
				//Left
				[bezier moveToPoint:NSMakePoint(NSMinX(aRect), NSMinY(aRect))];
				[bezier lineToPoint:NSMakePoint(NSMinX(aRect), NSMaxY(aRect))];
				//Bottom
				[bezier lineToPoint:NSMakePoint(NSMaxX(aRect), NSMaxY(aRect))];
			}
			[shadow setShadowOffset:NSMakeSize((_drawsRight ? 1.5 : -1.5), -1.5)];
			[shadow set];
			[bezier stroke];
		}
	} else {
		// unselected tab
		NSRect aRect = NSMakeRect(cellFrame.origin.x, cellFrame.origin.y, cellFrame.size.width, cellFrame.size.height);

		// rollover
		if([cell isHighlighted]) {
			[[NSColor colorWithCalibratedWhite:0.0 alpha:0.1] set];
			NSRectFillUsingOperation(aRect, NSCompositeSourceAtop);
		}

		// frame
		[lineColor set];

		if(orientation == PSMTabBarHorizontalOrientation) {
			[bezier moveToPoint:NSMakePoint(aRect.origin.x, aRect.origin.y)];
			[bezier lineToPoint:NSMakePoint(aRect.origin.x + aRect.size.width, aRect.origin.y)];
			if(!([cell tabState] & PSMTab_RightIsSelectedMask)) {
				//draw the tab divider
				[bezier lineToPoint:NSMakePoint(aRect.origin.x + aRect.size.width, aRect.origin.y + aRect.size.height)];
			}
			[bezier stroke];
		} else {
			//No outline for vertical
		}
	}

	[NSGraphicsContext restoreGraphicsState];
	[shadow release];
}

- (void)drawIconOfTabCell:(PSMTabBarCell *)cell withFrame:(NSRect)frame inTabBarControl:(PSMTabBarControl *)tabBarControl {

    if ([tabBarControl orientation] == PSMTabBarHorizontalOrientation) {
        if (![cell shouldDrawCloseButton] || ([cell shouldDrawCloseButton] && ![cell closeButtonOver] && ![cell closeButtonPressed])) {
            [cell _drawIconWithFrame:frame inTabBarControl:tabBarControl];
        }
    } else {
        if (![cell hasLargeImage])
            [cell _drawIconWithFrame:frame inTabBarControl:tabBarControl];
    }
}

- (void)drawCloseButtonOfTabCell:(PSMTabBarCell *)cell withFrame:(NSRect)frame inTabBarControl:(PSMTabBarControl *)tabBarControl {

    if ([tabBarControl orientation] == PSMTabBarHorizontalOrientation) {
    
        if (![cell hasIcon] || ([cell hasIcon] && [cell shouldDrawCloseButton] && ([cell closeButtonOver] || [cell closeButtonPressed])))
    
        [cell _drawCloseButtonWithFrame:frame inTabBarControl:tabBarControl];
    } else {
    
        if (![cell shouldDrawObjectCounter] || ([cell shouldDrawObjectCounter] && ([cell closeButtonOver] || [cell closeButtonPressed])))
            [cell _drawCloseButtonWithFrame:frame inTabBarControl:tabBarControl];
    }
}

- (void)drawObjectCounterOfTabCell:(PSMTabBarCell *)cell withFrame:(NSRect)frame inTabBarControl:(PSMTabBarControl *)tabBarControl {

    if ([tabBarControl orientation] == PSMTabBarHorizontalOrientation) {
        [cell _drawObjectCounterWithFrame:frame inTabBarControl:tabBarControl];
    } else {
        if (![cell shouldDrawCloseButton] || ([cell shouldDrawCloseButton] && ![cell closeButtonOver] && ![cell closeButtonPressed])) {
            [cell _drawObjectCounterWithFrame:frame inTabBarControl:tabBarControl];
        }
    }
}

#pragma mark -
#pragma mark Archiving

- (void)encodeWithCoder:(NSCoder *)aCoder {
	if([aCoder allowsKeyedCoding]) {
		[aCoder encodeObject:_closeButton forKey:@"closeButton"];
		[aCoder encodeObject:_closeButtonDown forKey:@"closeButtonDown"];
		[aCoder encodeObject:_closeButtonOver forKey:@"closeButtonOver"];
		[aCoder encodeObject:_closeDirtyButton forKey:@"closeDirtyButton"];
		[aCoder encodeObject:_closeDirtyButtonDown forKey:@"closeDirtyButtonDown"];
		[aCoder encodeObject:_closeDirtyButtonOver forKey:@"closeDirtyButtonOver"];
		[aCoder encodeObject:_addTabButtonImage forKey:@"addTabButtonImage"];
		[aCoder encodeObject:_addTabButtonPressedImage forKey:@"addTabButtonPressedImage"];
		[aCoder encodeObject:_addTabButtonRolloverImage forKey:@"addTabButtonRolloverImage"];
		[aCoder encodeBool:_drawsUnified forKey:@"drawsUnified"];
		[aCoder encodeBool:_drawsRight forKey:@"drawsRight"];
	}
}

- (id)initWithCoder:(NSCoder *)aDecoder {
	if((self = [super init])) {
		if([aDecoder allowsKeyedCoding]) {
			_closeButton = [[aDecoder decodeObjectForKey:@"closeButton"] retain];
			_closeButtonDown = [[aDecoder decodeObjectForKey:@"closeButtonDown"] retain];
			_closeButtonOver = [[aDecoder decodeObjectForKey:@"closeButtonOver"] retain];
			_closeDirtyButton = [[aDecoder decodeObjectForKey:@"closeDirtyButton"] retain];
			_closeDirtyButtonDown = [[aDecoder decodeObjectForKey:@"closeDirtyButtonDown"] retain];
			_closeDirtyButtonOver = [[aDecoder decodeObjectForKey:@"closeDirtyButtonOver"] retain];
			_addTabButtonImage = [[aDecoder decodeObjectForKey:@"addTabButtonImage"] retain];
			_addTabButtonPressedImage = [[aDecoder decodeObjectForKey:@"addTabButtonPressedImage"] retain];
			_addTabButtonRolloverImage = [[aDecoder decodeObjectForKey:@"addTabButtonRolloverImage"] retain];
			_drawsUnified = [aDecoder decodeBoolForKey:@"drawsUnified"];
			_drawsRight = [aDecoder decodeBoolForKey:@"drawsRight"];
		}
	}
	return self;
}

@end

