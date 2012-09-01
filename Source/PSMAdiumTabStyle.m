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
    
}  // -closeButtonImageOfType:

#pragma mark -
#pragma mark Determining Cell Size

- (CGFloat)tabCellHeight {

#warning Needs refactoring
    return kPSMTabBarControlHeight;
/*
    PSMTabBarOrientation orientation = [tabBar orientation];

	return((orientation == PSMTabBarHorizontalOrientation) ? kPSMTabBarControlHeight : kPSMTabBarControlSourceListHeight);
*/
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
}  // -drawingRectForBounds:ofTabCell:

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

    // calculate rect
    NSRect drawingRect = [cell drawingRectForBounds:theRect];
                
    NSSize iconSize = [icon size];
    
    NSSize scaledIconSize = [cell scaleImageWithSize:iconSize toFitInSize:NSMakeSize(iconSize.width, drawingRect.size.height) scalingType:NSImageScaleProportionallyDown];

    NSRect result;
    if (orientation == PSMTabBarHorizontalOrientation) {
        {
        NSRect constrainedDrawingRect = drawingRect;
/*
        NSRect closeButtonRect = [cell closeButtonRectForBounds:theRect];
        if (!NSEqualRects(closeButtonRect, NSZeroRect))
            {
            constrainedDrawingRect.origin.x += NSWidth(closeButtonRect) + kPSMTabBarCellPadding;
            constrainedDrawingRect.size.width -= NSWidth(closeButtonRect) + kPSMTabBarCellPadding;
            }
*/
        result = NSMakeRect(constrainedDrawingRect.origin.x, constrainedDrawingRect.origin.y, scaledIconSize.width, scaledIconSize.height);
        }
    } else {
        result = NSMakeRect(NSMaxX(drawingRect)-scaledIconSize.width-Adium_MARGIN_X, drawingRect.origin.y, scaledIconSize.width, scaledIconSize.height);
    }
    
    // center in available space (in case icon image is smaller than kPSMTabBarIconWidth)
    if(scaledIconSize.width < kPSMTabBarIconWidth) {
        result.origin.x += ceil((kPSMTabBarIconWidth - scaledIconSize.width) / 2.0);
    }

    if(scaledIconSize.height < kPSMTabBarIconWidth) {
        result.origin.y -= ceil((kPSMTabBarIconWidth - scaledIconSize.height) / 2.0 - 0.5);
    }

    return NSIntegralRect(result);    
    
}  // -iconRectForBounds:ofTabCell:

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

/*
- (NSRect)closeButtonRectForTabCell:(PSMTabBarCell *)cell withFrame:(NSRect)cellFrame {

	if([cell shouldDrawCloseButton] == NO) {
		return NSZeroRect;
	}
    
    PSMTabBarControl *tabBarControl = [cell controlView];
    PSMTabBarOrientation orientation = [tabBarControl orientation];

	NSRect result;
    result.origin = NSMakePoint(0.0, 0.0);
	result.size = [_closeButton size];

	switch(orientation) {
	case PSMTabBarHorizontalOrientation:
	{
		result.origin.x = cellFrame.origin.x + Adium_MARGIN_X;
		result.origin.y = cellFrame.origin.y + MARGIN_Y + 2.0;
		if([cell state] == NSOnState) {
			result.origin.y -= 1;
		}
		break;
	}

	case PSMTabBarVerticalOrientation:
	{
		result.origin.x = NSMaxX(cellFrame) - (Adium_MARGIN_X * 2) - NSWidth(result);
		result.origin.y = NSMinY(cellFrame) + (NSHeight(cellFrame) / 2) - (result.size.height / 2) + 1;
		break;
	}
	}

	return result;
}

- (NSRect)largeImageRectForTabCell:(PSMTabBarCell *)cell {

	if([cell hasLargeImage] == NO || orientation == PSMTabBarHorizontalOrientation) {
		return NSZeroRect;
	}

    NSRect drawingRect = [cell drawingRectForBounds:[cell frame]];
    
    NSImage *image = [[[cell representedObject] identifier] largeImage];
    
    NSSize scaledImageSize = [cell scaleImageWithSize:[image size] toFitInSize:NSMakeSize(kPSMTabBarLargeImageWidth, kPSMTabBarLargeImageHeight) scalingType:NSImageScaleProportionallyUpOrDown];
    
    NSRect result = NSMakeRect(drawingRect.origin.x,
                                         drawingRect.origin.y - ((scaledImageSize.height - scaledImageSize.height) / 2) - 0.5,
                                         scaledImageSize.width, scaledImageSize.height);

    if(scaledImageSize.width < kPSMTabBarIconWidth) {
        result.origin.x += (kPSMTabBarIconWidth - scaledImageSize.width) / 2.0;
    }
    if(scaledImageSize.height < drawingRect.size.height) {
        result.origin.y += (drawingRect.size.height - scaledImageSize.height) / 2.0;
    }
    
    return result;
}

- (NSRect)iconRectForTabCell:(PSMTabBarCell *)cell {
	if([cell hasIcon] == NO) {
		return NSZeroRect;
	}

    NSRect drawingRect = [cell drawingRectForBounds:[cell frame]];
    
    NSImage *icon = [[(NSTabViewItem*)[cell representedObject] identifier] icon];
    
    NSSize scaledSize = [cell scaleImageWithSize:[icon size] toFitInSize:NSMakeSize(kPSMTabBarIconWidth, drawingRect.size.height) scalingType:NSImageScaleProportionallyDown];

    NSRect result = NSMakeRect(drawingRect.origin.x, drawingRect.origin.y, scaledSize.width, scaledSize.height);
    
    if(scaledSize.width < kPSMTabBarIconWidth) {
        result.origin.x += (kPSMTabBarIconWidth - scaledSize.width) / 2.0;
    }
    if(scaledSize.height < drawingRect.size.height) {
        result.origin.y += (drawingRect.size.height - scaledSize.height) / 2.0;
    }
        
    return result;

//	NSRect cellFrame = [cell frame];
//	NSImage *icon = [[(NSTabViewItem*)[cell representedObject] identifier] icon];
//	NSSize iconSize = [icon size];
//
//	NSRect result;
//    result.origin = NSMakePoint(0.0, 0.0);
//	result.size = [cell scaleImageWithSize:iconSize toFitInSize:cellFrame.size scalingType:NSImageScaleProportionallyDown];
//
//	switch(orientation) {
//	case PSMTabBarHorizontalOrientation:
//		result.origin.x = cellFrame.origin.x + Adium_MARGIN_X;
//		result.origin.y = cellFrame.origin.y + MARGIN_Y;
//		break;
//
//	case PSMTabBarVerticalOrientation:
//		result.origin.x = NSMaxX(cellFrame) - (Adium_MARGIN_X * 2) - NSWidth(result);
//		result.origin.y = NSMinY(cellFrame) + (NSHeight(cellFrame) / 2) - (NSHeight(result) / 2) + 1;
//		break;
//	}
//
//	// For horizontal tabs, center in available space (in case icon image is smaller than kPSMTabBarIconWidth)
//	if(orientation == PSMTabBarHorizontalOrientation) {
//		if(iconSize.width < kPSMTabBarIconWidth) {
//			result.origin.x += (kPSMTabBarIconWidth - iconSize.width) / 2.0;
//		}
//		if(iconSize.height < kPSMTabBarIconWidth) {
//			result.origin.y += (kPSMTabBarIconWidth - iconSize.height) / 2.0;
//		}
//	}
//
//	if([cell state] == NSOnState) {
//		result.origin.y -= 1;
//	}
//
//	return result;
}

- (NSRect)indicatorRectForTabCell:(PSMTabBarCell *)cell {
	NSRect cellFrame = [cell frame];

	if([[cell indicator] isHidden]) {
		return NSZeroRect;
	}

	NSRect result;
	result.size = NSMakeSize(kPSMTabBarIndicatorWidth, kPSMTabBarIndicatorWidth);
	result.origin.x = cellFrame.origin.x + cellFrame.size.width - Adium_MARGIN_X - kPSMTabBarIndicatorWidth;
	result.origin.y = cellFrame.origin.y + MARGIN_Y;

	if([cell state] == NSOnState) {
		result.origin.y -= 1;
	}

	return result;
}

- (NSSize)sizeForObjectCounterRectForTabCell:(PSMTabBarCell *)cell {
	NSSize size;
	CGFloat countWidth = [[self attributedObjectCountValueForTabCell:cell] size].width;

	countWidth += (2 * kPSMObjectCounterRadius - 6.0 + kPSMAdiumCounterPadding);

	if(countWidth < kPSMObjectCounterMinWidth) {
		countWidth = kPSMObjectCounterMinWidth;
	}

	size = NSMakeSize(countWidth, 2 * kPSMObjectCounterRadius);     // temp

	return size;
}

- (NSRect)objectCounterRectForTabCell:(PSMTabBarCell *)cell {
	NSRect cellFrame;
	NSRect result;

	if([cell count] == 0) {
		return NSZeroRect;
	}

	cellFrame = [cell frame];
	result.size = [self sizeForObjectCounterRectForTabCell:cell];
	result.origin.x = NSMaxX(cellFrame) - Adium_MARGIN_X - result.size.width;
	result.origin.y = cellFrame.origin.y + MARGIN_Y + 1.0;

	if(![[cell indicator] isHidden]) {
		result.origin.x -= kPSMTabBarIndicatorWidth + Adium_CellPadding;
	}

	return result;
}
*/
/*
- (CGFloat)minimumWidthOfTabCell:(PSMTabBarCell *)cell {
	CGFloat resultWidth = 0.0;

	// left margin
	resultWidth = Adium_MARGIN_X;

	// close button?
	if([cell shouldDrawCloseButton]) {
		resultWidth += MAX([_closeButton size].width, NSWidth([self iconRectForTabCell:cell])) + Adium_CellPadding;
	}

	// icon?
	if ([cell hasIcon]) {
	        resultWidth += kPSMTabBarIconWidth + Adium_CellPadding;
    }

	// the label
	resultWidth += kPSMMinimumTitleWidth;

	// object counter?
	if(([cell count] > 0) && (orientation == PSMTabBarHorizontalOrientation)) {
		resultWidth += NSWidth([self objectCounterRectForTabCell:cell]) + Adium_CellPadding;
	}

	// indicator?
	if([[cell indicator] isHidden] == NO) {
		resultWidth += Adium_CellPadding + kPSMTabBarIndicatorWidth;
	}

	// right margin
	resultWidth += Adium_MARGIN_X;

	return ceil(resultWidth);
}

- (CGFloat)desiredWidthOfTabCell:(PSMTabBarCell *)cell {
	CGFloat resultWidth = 0.0;

	// left margin
	resultWidth = Adium_MARGIN_X;

	// close button?
	if([cell shouldDrawCloseButton]) {
		resultWidth += MAX([_closeButton size].width, NSWidth([self iconRectForTabCell:cell])) + Adium_CellPadding;
	}

	// icon?
	if ([cell hasIcon]) {
	        resultWidth += kPSMTabBarIconWidth + Adium_CellPadding;
	   }

	// the label
	resultWidth += [[cell attributedStringValue] size].width + Adium_CellPadding;

	// object counter?
	if(([cell count] > 0) && (orientation == PSMTabBarHorizontalOrientation)) {
		resultWidth += [self objectCounterRectForTabCell:cell].size.width + Adium_CellPadding;
	}

	// indicator?
	if([[cell indicator] isHidden] == NO) {
		resultWidth += Adium_CellPadding + kPSMTabBarIndicatorWidth;
	}

	// right margin
	resultWidth += Adium_MARGIN_X;

	return ceil(resultWidth);
}
*/

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

- (CGFloat)heightOfAttributedString:(NSAttributedString *)inAttributedString withWidth:(CGFloat)width {
	static NSMutableDictionary *cache;
	if(!cache) {
		cache = [[NSMutableDictionary alloc] init];
	}
	if([cache count] > 100) {    //100 items should be trivial in terms of memory overhead, but sufficient
		[cache removeAllObjects];
	}
	NSNumber *cachedHeight = [cache objectForKey:inAttributedString];
	if(cachedHeight) {
		return [cachedHeight doubleValue];
	} else{
		NSTextStorage           *textStorage = [[NSTextStorage alloc] initWithAttributedString:inAttributedString];
		NSTextContainer         *textContainer = [[NSTextContainer alloc] initWithContainerSize:NSMakeSize(width, 1e7)];
		NSLayoutManager         *layoutManager = [[NSLayoutManager alloc] init];

		//Configure
		[textContainer setLineFragmentPadding:0.0];
		[layoutManager addTextContainer:textContainer];
		[textStorage addLayoutManager:layoutManager];

		//Force the layout manager to layout its text
		(void)[layoutManager glyphRangeForTextContainer:textContainer];

		CGFloat height = [layoutManager usedRectForTextContainer:textContainer].size.height;

		[textStorage release];
		[textContainer release];
		[layoutManager release];

		[cache setObject:[NSNumber numberWithDouble:height] forKey:inAttributedString];

		return height;
	}
}

- (void)drawObjectCounterInCell:(PSMTabBarCell *)cell withRect:(NSRect)myRect {
	myRect.size.width -= kPSMAdiumCounterPadding;
	myRect.origin.x += kPSMAdiumCounterPadding;

	[[cell countColor] ?: [NSColor colorWithCalibratedWhite:0.3 alpha:0.6] set];
	NSBezierPath *path = [NSBezierPath bezierPath];
	[path setLineWidth:1.0];

	if([cell state] == NSOnState) {
		myRect.origin.y -= 1.0;
	}

	[path moveToPoint:NSMakePoint(NSMinX(myRect) + kPSMObjectCounterRadius, NSMinY(myRect))];
	[path lineToPoint:NSMakePoint(NSMaxX(myRect) - kPSMObjectCounterRadius, NSMinY(myRect))];
	[path appendBezierPathWithArcWithCenter:NSMakePoint(NSMaxX(myRect) - kPSMObjectCounterRadius, NSMinY(myRect) + kPSMObjectCounterRadius)
	 radius:kPSMObjectCounterRadius
	 startAngle:270.0
	 endAngle:90.0];
	[path lineToPoint:NSMakePoint(NSMinX(myRect) + kPSMObjectCounterRadius, NSMaxY(myRect))];
	[path appendBezierPathWithArcWithCenter:NSMakePoint(NSMinX(myRect) + kPSMObjectCounterRadius, NSMinY(myRect) + kPSMObjectCounterRadius)
	 radius:kPSMObjectCounterRadius
	 startAngle:90.0
	 endAngle:270.0];
	[path fill];

	// draw attributed string centered in area
	NSRect counterStringRect;
	NSAttributedString *counterString = [self attributedObjectCountValueForTabCell:cell];
	counterStringRect.size = [counterString size];
	counterStringRect.origin.x = myRect.origin.x + ((myRect.size.width - counterStringRect.size.width) / 2.0) + 0.25;
	counterStringRect.origin.y = myRect.origin.y + ((myRect.size.height - counterStringRect.size.height) / 2.0) + 0.5;
	[counterString drawInRect:counterStringRect];
}

/*
- (NSBezierPath *)bezierPathWithRoundedRect:(NSRect)rect radius:(CGFloat)radius {
	NSBezierPath        *path = [NSBezierPath bezierPath];
	NSPoint topLeft, topRight, bottomLeft, bottomRight;

	topLeft = NSMakePoint(rect.origin.x, rect.origin.y);
	topRight = NSMakePoint(rect.origin.x + rect.size.width, rect.origin.y);
	bottomLeft = NSMakePoint(rect.origin.x, rect.origin.y + rect.size.height);
	bottomRight = NSMakePoint(rect.origin.x + rect.size.width, rect.origin.y + rect.size.height);

	[path appendBezierPathWithArcWithCenter:NSMakePoint(topLeft.x + radius, topLeft.y + radius)
	 radius:radius
	 startAngle:180
	 endAngle:270
	 clockwise:NO];
	[path lineToPoint:NSMakePoint(topRight.x - radius, topRight.y)];

	[path appendBezierPathWithArcWithCenter:NSMakePoint(topRight.x - radius, topRight.y + radius)
	 radius:radius
	 startAngle:270
	 endAngle:0
	 clockwise:NO];
	[path lineToPoint:NSMakePoint(bottomRight.x, bottomRight.y - radius)];

	[path appendBezierPathWithArcWithCenter:NSMakePoint(bottomRight.x - radius, bottomRight.y - radius)
	 radius:radius
	 startAngle:0
	 endAngle:90
	 clockwise:NO];
	[path lineToPoint:NSMakePoint(bottomLeft.x + radius, bottomLeft.y)];

	[path appendBezierPathWithArcWithCenter:NSMakePoint(bottomLeft.x + radius, bottomLeft.y - radius)
	 radius:radius
	 startAngle:90
	 endAngle:180
	 clockwise:NO];
	[path lineToPoint:NSMakePoint(topLeft.x, topLeft.y + radius)];

	return path;
}
*/
/*
- (void)drawInteriorWithTabCell:(PSMTabBarCell *)cell inView:(NSView*)controlView {
	NSRect cellFrame = [cell frame];
    
    PSMTabBarOrientation orientation = [(PSMTabBarControl *)controlView orientation];
    
    NSRect drawingRect = [cell drawingRectForBounds:cellFrame];

	if((orientation == PSMTabBarVerticalOrientation) &&
	   [cell hasLargeImage]) {
		NSImage *image = [[[cell representedObject] identifier] largeImage];

        NSRect imageDrawingRect = [cell largeImageRectForBounds:cellFrame];
        
		[NSGraphicsContext saveGraphicsState];
                
		//Create Rounding.
		CGFloat userIconRoundingRadius = (kPSMTabBarLargeImageWidth / 4.0);
		if(userIconRoundingRadius > 3.0) {
			userIconRoundingRadius = 3.0;
		}
        
		NSBezierPath *clipPath = [self bezierPathWithRoundedRect:imageDrawingRect radius:userIconRoundingRadius];
		[clipPath addClip];        
  
        [image drawInRect:imageDrawingRect fromRect:NSZeroRect operation:NSCompositeSourceOver fraction:1.0 respectFlipped:YES hints:nil];
    
		[NSGraphicsContext restoreGraphicsState];
        
        drawingRect.origin.x += imageDrawingRect.size.width + Adium_CellPadding;
        drawingRect.size.width -= imageDrawingRect.size.width + Adium_CellPadding;   
	}

	// label rect
	NSRect labelRect = drawingRect;
	switch(orientation) {
	case PSMTabBarHorizontalOrientation :
		labelRect.origin.y += 1;
		break;
	case PSMTabBarVerticalOrientation:
		break;
	}

	if([cell shouldDrawCloseButton]) {
		// The close button and the icon (if present) are drawn combined, changing on-hover 
		NSRect closeButtonRect = [cell closeButtonRectForBounds:cellFrame];
		NSRect iconRect = [cell iconRectForBounds:cellFrame];
		NSRect localDrawingRect;
		NSImage *closeButtonOrIcon = nil;

		if([cell hasIcon] && orientation == PSMTabBarHorizontalOrientation) {
            // If the cell has an icon and a close button, determine which rect should be used        and use it consistently
            // This only matters for horizontal tabs; vertical tabs look fine without making this adjustment.
			if(NSWidth(iconRect) > NSWidth(closeButtonRect)) {
				closeButtonRect.origin.x = NSMinX(iconRect) + NSWidth(iconRect) / 2 - NSWidth(closeButtonRect) / 2;
			}
		}

		if([cell closeButtonPressed]) {
			closeButtonOrIcon = ([cell isEdited] ? _closeDirtyButtonDown : _closeButtonDown);
			localDrawingRect = closeButtonRect;
		} else if([cell closeButtonOver]) {
			closeButtonOrIcon = ([cell isEdited] ? _closeDirtyButtonOver : _closeButtonOver);
			localDrawingRect = closeButtonRect;
		} else if((orientation == PSMTabBarVerticalOrientation) &&
				  ([cell count] > 0)) {
			// In vertical tabs, the count indicator supercedes the icon 
			NSSize counterSize = [cell objectCounterSize];
			if(counterSize.width > NSWidth(closeButtonRect)) {
				closeButtonRect.origin.x -= (counterSize.width - NSWidth(closeButtonRect));
				closeButtonRect.size.width = counterSize.width;
			}

			closeButtonRect.origin.y = cellFrame.origin.y + ((NSHeight(cellFrame) - counterSize.height) / 2);
			closeButtonRect.size.height = counterSize.height;

			localDrawingRect = closeButtonRect;
			[self drawObjectCounterInCell:cell withRect:localDrawingRect];
			// closeButtonOrIcon == nil 
		} else if([cell hasIcon]) {
			closeButtonOrIcon = [[(NSTabViewItem*)[cell representedObject] identifier] icon];
			localDrawingRect = iconRect;
		} else {
			closeButtonOrIcon = ([cell isEdited] ? _closeDirtyButton : _closeButton);
			localDrawingRect = closeButtonRect;
		}

        [closeButtonOrIcon drawInRect:localDrawingRect fromRect:NSZeroRect operation:NSCompositeSourceOver fraction:1.0 respectFlipped:YES hints:nil];

		// scoot label over
		switch(orientation) {
		case PSMTabBarHorizontalOrientation:
		{
			CGFloat oldOrigin = labelRect.origin.x;
			if(NSWidth(iconRect) > NSWidth(closeButtonRect)) {
				labelRect.origin.x = (NSMaxX(iconRect) + (Adium_CellPadding * 2));
			} else {
				labelRect.origin.x = (NSMaxX(closeButtonRect) + (Adium_CellPadding * 2));
			}
			labelRect.size.width -= (NSMinX(labelRect) - oldOrigin);
			break;
		}
		case PSMTabBarVerticalOrientation:
		{
			//Generate the remaining label rect directly from the location of the close button, allowing for padding
			if(NSWidth(iconRect) > NSWidth(closeButtonRect)) {
				labelRect.size.width = NSMinX(iconRect) - Adium_CellPadding - NSMinX(labelRect);
			} else {
				labelRect.size.width = NSMinX(closeButtonRect) - Adium_CellPadding - NSMinX(labelRect);
			}

			break;
		}
		}
	} else if([cell hasIcon]) {
		// The close button is disabled; the cell has an icon 
		NSRect iconRect = [cell iconRectForBounds:cellFrame];
		NSImage *icon = [[(NSTabViewItem*)[cell representedObject] identifier] icon];

        [icon drawInRect:iconRect fromRect:NSZeroRect operation:NSCompositeSourceOver fraction:1.0 respectFlipped:YES hints:nil];

		// scoot label over by the size of the standard close button
		switch(orientation) {
		case PSMTabBarHorizontalOrientation:
			labelRect.origin.x += (NSWidth(iconRect) + Adium_CellPadding);
			labelRect.size.width -= (NSWidth(iconRect) + Adium_CellPadding);
			break;
		case PSMTabBarVerticalOrientation:
            labelRect.origin.x += (NSWidth(iconRect) + Adium_CellPadding);        
			labelRect.size.width -= (NSWidth(iconRect) + Adium_CellPadding);
			break;
		}
	}

	if(orientation == PSMTabBarHorizontalOrientation && [cell state] == NSOnState) {
		labelRect.origin.y -= 1;
	}

	if(![[cell indicator] isHidden]) {
		labelRect.size.width -= (kPSMTabBarIndicatorWidth + Adium_CellPadding);
	}

	// object counter
	//The object counter takes up space horizontally...
	if(([cell count] > 0) &&
	   (orientation == PSMTabBarHorizontalOrientation)) {
		NSRect counterRect = [cell objectCounterRectForBounds:cellFrame];

		[self drawObjectCounterInCell:cell withRect:counterRect];
		labelRect.size.width -= NSWidth(counterRect) + Adium_CellPadding;
	}

	// draw label
	NSAttributedString *attributedString = [cell attributedStringValue];
	if(orientation == PSMTabBarVerticalOrientation) {
		//Calculate the centered rect
		CGFloat stringHeight = [self heightOfAttributedString:attributedString withWidth:NSWidth(labelRect)];
		if(stringHeight < labelRect.size.height) {
			labelRect.origin.y += (NSHeight(labelRect) - stringHeight) / 2.0;
		}
	}

	[attributedString drawInRect:labelRect];
}
*/

- (void)drawBezelOfTabCell:(PSMTabBarCell *)cell withFrame:(NSRect)frame inView:(id)controlView {

    NSRect cellFrame = [cell frame];
	NSColor *lineColor = nil;
	NSBezierPath *bezier = [NSBezierPath bezierPath];
	lineColor = [NSColor grayColor];
    
    PSMTabBarControl *tabBarControl = (PSMTabBarControl *)[cell controlView];
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

/*
- (void)drawTabCell:(PSMTabBarCell *)cell {
	NSRect cellFrame = [cell frame];
	NSColor *lineColor = nil;
	NSBezierPath *bezier = [NSBezierPath bezierPath];
	lineColor = [NSColor grayColor];
    
    PSMTabBarOrientation orientation = [(PSMTabBarControl *)[cell controlView] orientation];

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
				if([[[tabBar tabView] window] isKeyWindow]) {
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
				if([[[tabBar tabView] window] isKeyWindow]) {
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

	[self drawInteriorWithTabCell:cell inView:[cell controlView]];
}
*/

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
			[cell drawWithFrame:[cell frame] inView:tabBarControl];
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
