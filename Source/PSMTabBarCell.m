//
//  PSMTabBarCell.m
//  PSMTabBarControl
//
//  Created by John Pannell on 10/13/05.
//  Copyright 2005 Positive Spin Media. All rights reserved.
//

#import "PSMTabBarCell.h"
#import "PSMTabBarControl.h"
#import "PSMTabStyle.h"
#import "PSMProgressIndicator.h"
#import "PSMTabDragAssistant.h"

@interface PSMTabBarControl (Private)
- (void)update;
@end

@implementation PSMTabBarCell

@synthesize tabState = _tabState;
@synthesize hasCloseButton = _hasCloseButton;
@synthesize hasIcon = _hasIcon;
@synthesize hasLargeImage = _hasLargeImage;
@synthesize count = _count;
@synthesize countColor = _countColor;
@synthesize isPlaceholder = _isPlaceholder;
@synthesize isEdited = _isEdited;
@synthesize closeButtonPressed = _closeButtonPressed;
@synthesize closeButtonTrackingTag = _closeButtonTrackingTag;
@synthesize cellTrackingTag = _cellTrackingTag;

#pragma mark -
#pragma mark Creation/Destruction
- (id)initWithControlView:(PSMTabBarControl *)controlView {
	if((self = [super init])) {
		_controlView = controlView;
		_closeButtonTrackingTag = 0;
		_cellTrackingTag = 0;
		_closeButtonOver = NO;
		_closeButtonPressed = NO;
		_indicator = [[PSMProgressIndicator alloc] initWithFrame:NSMakeRect(0.0, 0.0, kPSMTabBarIndicatorWidth, kPSMTabBarIndicatorWidth)];
		[_indicator setStyle:NSProgressIndicatorSpinningStyle];
		[_indicator setAutoresizingMask:NSViewMinYMargin];
		[_indicator setControlSize: NSSmallControlSize];
		_hasCloseButton = YES;
		_isCloseButtonSuppressed = NO;
		_count = 0;
		_countColor = nil;
		_isEdited = NO;
		_isPlaceholder = NO;
	}
	return self;
}

- (id)initPlaceholderWithFrame:(NSRect)frame expanded:(BOOL)value inControlView:(PSMTabBarControl *)controlView {
	if((self = [super init])) {
		_controlView = controlView;
		_isPlaceholder = YES;
		if(!value) {
			if([controlView orientation] == PSMTabBarHorizontalOrientation) {
				frame.size.width = 0.0;
			} else {
				frame.size.height = 0.0;
			}
		}
		[self setFrame:frame];
		_closeButtonTrackingTag = 0;
		_cellTrackingTag = 0;
		_closeButtonOver = NO;
		_closeButtonPressed = NO;
		_indicator = nil;
		_hasCloseButton = YES;
		_isCloseButtonSuppressed = NO;
		_count = 0;
		_countColor = nil;
		_isEdited = NO;

		if(value) {
			[self setCurrentStep:(kPSMTabDragAnimationSteps - 1)];
		} else {
			[self setCurrentStep:0];
		}
	}
	return self;
}

- (void)dealloc {
	[_countColor release];

	[_indicator removeFromSuperviewWithoutNeedingDisplay];

	[_indicator release];
	[super dealloc];
}

#pragma mark -
#pragma mark Accessors

- (id)controlView {
	return _controlView;
}

- (void)setControlView:(id)view {
	// no retain release pattern, as this simply switches a tab to another view.
	_controlView = view;
}

- (CGFloat)width {
	return _frame.size.width;
}

- (NSRect)frame {
	return _frame;
}

- (void)setFrame:(NSRect)rect {
	_frame = rect;

	//move the status indicator along with the rest of the cell
	if(![[self indicator] isHidden] && ![_controlView isTabBarHidden]) {
		[[self indicator] setFrame:[self indicatorRectForBounds:rect]];
	}
}

- (void)setStringValue:(NSString *)aString {
	[super setStringValue:aString];
	_stringSize = [[self attributedStringValue] size];
	// need to redisplay now - binding observation was too quick.
	[_controlView update];
}

- (NSSize)stringSize {
	return _stringSize;
}

- (NSAttributedString *)attributedStringValue {
	return [(id < PSMTabStyle >)[(PSMTabBarControl *)_controlView style] attributedStringValueForTabCell:self];
}

- (NSProgressIndicator *)indicator {
	return _indicator;
}

- (BOOL)isInOverflowMenu {
	return _isInOverflowMenu;
}

- (void)setIsInOverflowMenu:(BOOL)value {
	if(_isInOverflowMenu != value) {
		_isInOverflowMenu = value;
		if([[[self controlView] delegate] respondsToSelector:@selector(tabView:tabViewItem:isInOverflowMenu:)]) {
			[[[self controlView] delegate] tabView:[self controlView] tabViewItem:[self representedObject] isInOverflowMenu:_isInOverflowMenu];
		}
	}
}

- (BOOL)closeButtonOver {
	return(_closeButtonOver && ([_controlView allowsBackgroundTabClosing] || ([self tabState] & PSMTab_SelectedMask) || [[NSApp currentEvent] modifierFlags] & NSCommandKeyMask));
}

- (void)setCloseButtonOver:(BOOL)value {
	_closeButtonOver = value;
}

- (void)setCloseButtonSuppressed:(BOOL)suppress;
{
	_isCloseButtonSuppressed = suppress;
}

- (BOOL)isCloseButtonSuppressed;
{
	return _isCloseButtonSuppressed;
}

- (NSInteger)currentStep {
	return _currentStep;
}

- (void)setCurrentStep:(NSInteger)value {
	if(value < 0) {
		value = 0;
	}

	if(value > (kPSMTabDragAnimationSteps - 1)) {
		value = (kPSMTabDragAnimationSteps - 1);
	}

	_currentStep = value;
}

#pragma mark -
#pragma mark Bindings

- (void)observeValueForKeyPath:(NSString *)keyPath ofObject:(id)object change:(NSDictionary *)change context:(void *)context {
	// the progress indicator, label, icon, or count has changed - redraw the control view
	//[_controlView update];
	//I seem to have run into some odd issue with update not being called at the right time. This seems to avoid the problem.
	[_controlView performSelector:@selector(update) withObject:nil afterDelay:0.0];
}

#pragma mark -
#pragma mark Providing Images

- (NSImage *)closeButtonImageOfType:(PSMCloseButtonImageType)type {

    id <PSMTabStyle> tabStyle = [(PSMTabBarControl *)_controlView style];
    
    if ([tabStyle respondsToSelector:@selector(closeButtonImageOfType:forTabCell:)]) {
        return [tabStyle closeButtonImageOfType:PSMCloseButtonImageTypeStandard forTabCell:self];
    // use standard image
    } else {
        switch (type) {
            case PSMCloseButtonImageTypeStandard:
                return [NSImage imageNamed:@"TabClose_Front"];
            case PSMCloseButtonImageTypeRollover:
                return [NSImage imageNamed:@"TabClose_Front_Rollover"];
            case PSMCloseButtonImageTypePressed:
                return [NSImage imageNamed:@"TabClose_Front_Pressed"];
                
            case PSMCloseButtonImageTypeDirty:
                return [NSImage imageNamed:@"TabClose_Dirty"];
            case PSMCloseButtonImageTypeDirtyRollover:
                return [NSImage imageNamed:@"TabClose_Dirty_Rollover"];
            case PSMCloseButtonImageTypeDirtyPressed:
                return [NSImage imageNamed:@"TabClose_Dirty_Pressed"];
                
            default:
                break;
        }
        
        return nil;
    }
    
    
}  // -closeButtonImageOfType:

#pragma mark -
#pragma mark Determining Cell Size

- (NSRect)drawingRectForBounds:(NSRect)theRect {

    id <PSMTabStyle> tabStyle = [(PSMTabBarControl *)_controlView style];
    if ([tabStyle respondsToSelector:@selector(drawingRectForBounds:ofTabCell:)])
        return [tabStyle drawingRectForBounds:theRect ofTabCell:self];
    else
        return NSInsetRect(theRect, MARGIN_X, MARGIN_Y);
}

- (NSRect)titleRectForBounds:(NSRect)theRect {

    id <PSMTabStyle> tabStyle = [(PSMTabBarControl *)_controlView style];
    if ([tabStyle respondsToSelector:@selector(titleRectForBounds:ofTabCell:)])
        return [tabStyle titleRectForBounds:theRect ofTabCell:self];
    else {
    
        NSRect drawingRect = [self drawingRectForBounds:theRect];

        NSRect constrainedDrawingRect = drawingRect;

        NSRect closeButtonRect = [self closeButtonRectForBounds:theRect];
        if (!NSEqualRects(closeButtonRect, NSZeroRect))
            {
            constrainedDrawingRect.origin.x += NSWidth(closeButtonRect)  + kPSMTabBarCellPadding;
            constrainedDrawingRect.size.width -= NSWidth(closeButtonRect) + kPSMTabBarCellPadding;
            }
            
        NSRect iconRect = [self iconRectForBounds:theRect];
        if (!NSEqualRects(iconRect, NSZeroRect))
            {
            constrainedDrawingRect.origin.x += NSWidth(iconRect)  + kPSMTabBarCellPadding;
            constrainedDrawingRect.size.width -= NSWidth(iconRect) + kPSMTabBarCellPadding;
            }
            
        NSRect indicatorRect = [self indicatorRectForBounds:theRect];
        if (!NSEqualRects(indicatorRect, NSZeroRect))
            {
            constrainedDrawingRect.size.width -= NSWidth(indicatorRect) + kPSMTabBarCellPadding;
            }

        NSRect counterBadgeRect = [self objectCounterRectForBounds:theRect];
        if (!NSEqualRects(counterBadgeRect, NSZeroRect))
            {
            constrainedDrawingRect.size.width -= NSWidth(counterBadgeRect) + kPSMTabBarCellPadding;
            }
                                
        NSAttributedString *attrString = [self attributedStringValue];
        if ([attrString length] == 0)
            return NSZeroRect;
            
        NSSize stringSize = [attrString size];
        
        NSRect result = NSMakeRect(constrainedDrawingRect.origin.x, drawingRect.origin.y+ceil((drawingRect.size.height-stringSize.height)/2), constrainedDrawingRect.size.width, stringSize.height);
                        
        return NSIntegralRect(result);
        }
}

- (NSRect)iconRectForBounds:(NSRect)theRect {

    id <PSMTabStyle> tabStyle = [(PSMTabBarControl *)_controlView style];
    if ([tabStyle respondsToSelector:@selector(iconRectForBounds:ofTabCell:)]) {
        return [tabStyle iconRectForBounds:theRect ofTabCell:self];
    } else {
    
        if (![self hasIcon])
            return NSZeroRect;

        NSImage *icon = [[(NSTabViewItem*)[self representedObject] identifier] icon];
        if (!icon)
            return NSZeroRect;
    
        // calculate rect
        NSRect drawingRect = [self drawingRectForBounds:theRect];

        NSRect constrainedDrawingRect = drawingRect;

        NSRect closeButtonRect = [self closeButtonRectForBounds:theRect];
        if (!NSEqualRects(closeButtonRect, NSZeroRect))
            {
            constrainedDrawingRect.origin.x += NSWidth(closeButtonRect)  + kPSMTabBarCellPadding;
            constrainedDrawingRect.size.width -= NSWidth(closeButtonRect) + kPSMTabBarCellPadding;
            }
                    
        NSSize iconSize = [icon size];
        
        NSSize scaledIconSize = [self scaleImageWithSize:iconSize toFitInSize:NSMakeSize(iconSize.width, constrainedDrawingRect.size.height) scalingType:NSImageScaleProportionallyDown];

        NSRect result = NSMakeRect(constrainedDrawingRect.origin.x, constrainedDrawingRect.origin.y, scaledIconSize.width, scaledIconSize.height);
    
		// center in available space (in case icon image is smaller than kPSMTabBarIconWidth)
		if(scaledIconSize.width < kPSMTabBarIconWidth) {
			result.origin.x += ceil((kPSMTabBarIconWidth - scaledIconSize.width) / 2.0);
		}

		if(scaledIconSize.height < kPSMTabBarIconWidth) {
			result.origin.y -= ceil((kPSMTabBarIconWidth - scaledIconSize.height) / 2.0 - 0.5);
		}

        return NSIntegralRect(result);
    }
}

- (NSRect)largeImageRectForBounds:(NSRect)theRect {

    // support for large images for horizontal orientation only
    if ([(PSMTabBarControl *)[self controlView] orientation] == PSMTabBarHorizontalOrientation)
        return NSZeroRect;

    id <PSMTabStyle> tabStyle = [(PSMTabBarControl *)_controlView style];
    if ([tabStyle respondsToSelector:@selector(largeImageRectForBounds:ofTabCell:)])
        return [tabStyle largeImageRectForBounds:theRect ofTabCell:self];
    else
        return theRect;
}

- (NSRect)indicatorRectForBounds:(NSRect)theRect {

    id <PSMTabStyle> tabStyle = [(PSMTabBarControl *)_controlView style];
    if ([tabStyle respondsToSelector:@selector(indicatorRectForBounds:ofTabCell:)])
        return [tabStyle indicatorRectForBounds:theRect ofTabCell:self];
    else
        {
        if([[self indicator] isHidden]) {
            return NSZeroRect;
        }
    
        // calculate rect
        NSRect drawingRect = [self drawingRectForBounds:theRect];

        NSSize indicatorSize = NSMakeSize(kPSMTabBarIndicatorWidth, kPSMTabBarIndicatorWidth);
        
        NSRect result = NSMakeRect(NSMaxX(drawingRect)-indicatorSize.width,NSMidY(drawingRect)-ceil(indicatorSize.height/2),indicatorSize.width,indicatorSize.height);
        
        return NSIntegralRect(result);
        }
}

- (NSSize)objectCounterSize
{
    id <PSMTabStyle> tabStyle = [(PSMTabBarControl *)_controlView style];

    if ([tabStyle respondsToSelector:@selector(objectCounterSizeForTabCell:)]) {
        return [tabStyle objectCounterSizeOfTabCell:self];
    } else {
        if([self count] == 0) {
            return NSZeroSize;
        }
        
        // get badge width
        CGFloat countWidth = [[tabStyle attributedObjectCountValueForTabCell:self] size].width;
            countWidth += (2 * kPSMObjectCounterRadius - 6.0);
            if(countWidth < kPSMObjectCounterMinWidth) {
                countWidth = kPSMObjectCounterMinWidth;
            }
        
        return NSMakeSize(countWidth, 2 * kPSMObjectCounterRadius);
    }
    
}  // -objectCounterSize

- (NSRect)objectCounterRectForBounds:(NSRect)theRect {

    id <PSMTabStyle> tabStyle = [(PSMTabBarControl *)_controlView style];
    if ([tabStyle respondsToSelector:@selector(objectCounterRectForBounds:ofTabCell:)]) {
        return [tabStyle objectCounterRectForBounds:theRect ofTabCell:self];
    } else {
    	if([self count] == 0) {
            return NSZeroRect;
        }

        NSRect drawingRect = [self drawingRectForBounds:theRect];

        NSRect constrainedDrawingRect = drawingRect;

        NSRect indicatorRect = [self indicatorRectForBounds:theRect];
        if (!NSEqualRects(indicatorRect, NSZeroRect))
            {
            constrainedDrawingRect.size.width -= NSWidth(indicatorRect) + kPSMTabBarCellPadding;
            }
        
        NSSize counterBadgeSize = [self objectCounterSize];
        
        // calculate rect
        NSRect result;
        result.size = counterBadgeSize; // temp
        result.origin.x = NSMaxX(constrainedDrawingRect)-counterBadgeSize.width;
        result.origin.y = ceil(constrainedDrawingRect.origin.y+(constrainedDrawingRect.size.height-result.size.height)/2);

        if(![[self indicator] isHidden]) {
            result.origin.x -= kPSMTabBarCellPadding;
        }
                    
        return NSIntegralRect(result);
    }
}

- (NSRect)closeButtonRectForBounds:(NSRect)theRect {
    
    id <PSMTabStyle> tabStyle = [(PSMTabBarControl *)_controlView style];
    
    // ask style for rect if available
    if ([tabStyle respondsToSelector:@selector(closeButtonRectForBounds:ofTabCell:)]) {
        return [tabStyle closeButtonRectForBounds:theRect ofTabCell:self];
    // default handling
    } else {
        if ([self shouldDrawCloseButton] == NO) {
            return NSZeroRect;
        }
        
        // ask style for image
        NSImage *image = [self closeButtonImageOfType:PSMCloseButtonImageTypeStandard];            
        if (!image)
            return NSZeroRect;
        
        // calculate rect
        NSRect drawingRect = [self drawingRectForBounds:theRect];
        
        NSSize imageSize = [image size];
        
        NSSize scaledImageSize = [self scaleImageWithSize:imageSize toFitInSize:NSMakeSize(imageSize.width, drawingRect.size.height) scalingType:NSImageScaleProportionallyDown];

        NSRect result = NSMakeRect(drawingRect.origin.x, drawingRect.origin.y, scaledImageSize.width, scaledImageSize.height);

        if(scaledImageSize.height < drawingRect.size.height) {
            result.origin.y += ceil((drawingRect.size.height - scaledImageSize.height) / 2.0);
        }
    
        return NSIntegralRect(result);
    }
}

- (CGFloat)minimumWidthOfCell {

    id < PSMTabStyle > style = [(PSMTabBarControl *)_controlView style];
    if ([style respondsToSelector:@selector(minimumWidthOfTabCell)]) {
        return [style minimumWidthOfTabCell:self];
    } else {
        
        CGFloat resultWidth = 0.0;

        // left margin
        resultWidth = MARGIN_X;

        // close button?
        if ([self shouldDrawCloseButton]) {
            NSImage *image = [self closeButtonImageOfType:PSMCloseButtonImageTypeStandard];
            resultWidth += [image size].width + kPSMTabBarCellPadding;
        }

        // icon?
        if([self hasIcon]) {
            resultWidth += kPSMTabBarIconWidth + kPSMTabBarCellPadding;
        }

        // the label
        resultWidth += kPSMMinimumTitleWidth;

        // object counter?
        if([self count] > 0) {
            resultWidth += [self objectCounterSize].width + kPSMTabBarCellPadding;
        }

        // indicator?
        if([[self indicator] isHidden] == NO) {
            resultWidth += kPSMTabBarCellPadding + kPSMTabBarIndicatorWidth;
        }

        // right margin
        resultWidth += MARGIN_X;

        return ceil(resultWidth);
    }
}

- (CGFloat)desiredWidthOfCell {

    id < PSMTabStyle > style = [(PSMTabBarControl *)_controlView style];
    if ([style respondsToSelector:@selector(desiredWidthOfTabCell)]) {
        return [style desiredWidthOfTabCell:self];
    } else {    
        CGFloat resultWidth = 0.0;

        // left margin
        resultWidth = MARGIN_X;

        // close button?
        if ([self shouldDrawCloseButton]) {
            NSImage *image = [self closeButtonImageOfType:PSMCloseButtonImageTypeStandard];
            resultWidth += [image size].width + kPSMTabBarCellPadding;
        }

        // icon?
        if([self hasIcon]) {
            resultWidth += kPSMTabBarIconWidth + kPSMTabBarCellPadding;
        }

        // the label
        resultWidth += [[self attributedStringValue] size].width;

        // object counter?
        if([self count] > 0) {
            resultWidth += [self objectCounterSize].width + kPSMTabBarCellPadding;
        }

        // indicator?
        if([[self indicator] isHidden] == NO) {
            resultWidth += kPSMTabBarCellPadding + kPSMTabBarIndicatorWidth;
        }

        // right margin
        resultWidth += MARGIN_X;

        return ceil(resultWidth);    
    }
}

#pragma mark -
#pragma mark Image Scaling

static inline NSSize scaleProportionally(NSSize imageSize, NSSize canvasSize, BOOL scaleUpOrDown) {

    CGFloat ratio;

    if (imageSize.width <= 0 || imageSize.height <= 0) {
      return NSMakeSize(0, 0);
    }

    // get the smaller ratio and scale the image size with it
    ratio = MIN(canvasSize.width / imageSize.width,
	      canvasSize.height / imageSize.height);
  
    // Only scale down, unless scaleUpOrDown is YES
    if (ratio < 1.0 || scaleUpOrDown)
        {
        imageSize.width *= ratio;
        imageSize.height *= ratio;
        }
    
    return imageSize;
} 

- (NSSize)scaleImageWithSize:(NSSize)imageSize toFitInSize:(NSSize)canvasSize scalingType:(NSImageScaling)scalingType {

    NSSize result;
  
    switch (scalingType)  {
        case NSImageScaleProportionallyDown:
            result = scaleProportionally (imageSize, canvasSize, NO);
            break;
        case NSImageScaleAxesIndependently:
            result = canvasSize;
            break;
        default:
        case NSImageScaleNone:
            result = imageSize;
            break;
        case NSImageScaleProportionallyUpOrDown:
            result = scaleProportionally (imageSize, canvasSize, YES);
            break;
    }
    
    return result;
}

#pragma mark -
#pragma mark Drawing

- (BOOL)shouldDrawCloseButton
{
    return [self hasCloseButton] && ![self isCloseButtonSuppressed];
}  // -shouldDrawCloseButton

- (void)drawWithFrame:(NSRect)cellFrame inView:(NSView *)controlView {
	if(_isPlaceholder) {
		[[NSColor colorWithCalibratedWhite:0.0 alpha:0.2] set];
		NSRectFillUsingOperation(cellFrame, NSCompositeSourceAtop);
		return;
	}

    id <PSMTabStyle> style = [(PSMTabBarControl *)controlView style];
    
    // legacy support
    if ([style respondsToSelector:@selector(drawTabCell:)]) {
        [(id < PSMTabStyle >)[(PSMTabBarControl *)_controlView style] drawTabCell:self];
        return;
    }
    
    // draw bezel
    if ([style respondsToSelector:@selector(drawBezelOfTabCell:withFrame:inView:)])
        [style drawBezelOfTabCell:self withFrame:cellFrame inView:controlView];
        
    // draw interior
    [self drawInteriorWithFrame:cellFrame inView:controlView];
}  // -drawWithFrame:inView:

- (void)drawInteriorWithFrame:(NSRect)cellFrame inView:(NSView *)controlView {
    id <PSMTabStyle> style = [(PSMTabBarControl *)controlView style];
    
    if ([style respondsToSelector:@selector(drawInteriorOfTabCell:withFrame:inView:)]) {
        [style drawInteriorOfTabCell:self withFrame:cellFrame inView:controlView];
    } else {
        NSRect componentRect;
        
        componentRect = [self largeImageRectForBounds:cellFrame];
        if (!NSEqualRects(componentRect, NSZeroRect))
            [self drawLargeImageWithFrame:cellFrame inView:controlView];
            
        componentRect = [self iconRectForBounds:cellFrame];
        if (!NSEqualRects(componentRect, NSZeroRect))
            [self drawIconWithFrame:cellFrame inView:controlView];
            
        componentRect = [self titleRectForBounds:cellFrame];
        if (!NSEqualRects(componentRect, NSZeroRect))
            [self drawTitleWithFrame:cellFrame inView:controlView];
            
        componentRect = [self objectCounterRectForBounds:cellFrame];
        if (!NSEqualRects(componentRect, NSZeroRect))
            [self drawObjectCounterWithFrame:cellFrame inView:controlView];
            
        componentRect = [self indicatorRectForBounds:cellFrame];
        if (!NSEqualRects(componentRect, NSZeroRect))
            [self drawIndicatorWithFrame:cellFrame inView:controlView];
            
        componentRect = [self closeButtonRectForBounds:cellFrame];
        if (!NSEqualRects(componentRect, NSZeroRect))
            [self drawCloseButtonWithFrame:cellFrame inView:controlView];
    }
    
}  // -drawInteriorWithFrame:inView:

- (void)drawLargeImageWithFrame:(NSRect)frame inView:(NSView *)controlView {
    
    id <PSMTabStyle> style = [(PSMTabBarControl *)controlView style];
    if ([style respondsToSelector:@selector(drawLargeImageOfTabCell:withFrame:inView:)]) {
        [style drawLargeImageOfTabCell:self withFrame:frame inView:controlView];
    } else {
    
    
    }
    
}  // -drawLargeImageWithFrame:inView:

- (void)drawIconWithFrame:(NSRect)frame inView:(NSView *)controlView {

    id <PSMTabStyle> style = [(PSMTabBarControl *)controlView style];
    if ([style respondsToSelector:@selector(drawIconOfTabCell:withFrame:inView:)]) {
        [style drawIconOfTabCell:self withFrame:frame inView:controlView];
    } else {
    
        NSRect iconRect = [self iconRectForBounds:frame];
        
		NSImage *icon = [[(NSTabViewItem*)[self representedObject] identifier] icon];

        [icon drawInRect:iconRect fromRect:NSZeroRect operation:NSCompositeSourceOver fraction:1.0 respectFlipped:YES hints:nil];       
    }
    
}  // -drawIconWithFrame:inView:

- (void)drawTitleWithFrame:(NSRect)frame inView:(NSView *)controlView {

    id <PSMTabStyle> style = [(PSMTabBarControl *)controlView style];
    if ([style respondsToSelector:@selector(drawTitleOfTabCell:withFrame:inView:)]) {
        [style drawTitleOfTabCell:self withFrame:frame inView:controlView];
    } else {
        NSRect rect = [self titleRectForBounds:frame];
 
        // draw title
        [[self attributedStringValue] drawInRect:rect];
    }
}  // -drawTitleWithFrame:inView:

- (void)drawObjectCounterWithFrame:(NSRect)frame inView:(NSView *)controlView {

    id <PSMTabStyle> style = [(PSMTabBarControl *)controlView style];
    if ([style respondsToSelector:@selector(drawObjectCounterOfTabCell:withFrame:inView:)]) {
        [style drawObjectCounterOfTabCell:self withFrame:frame inView:controlView];
    } else {

        // set color
		[[self countColor] ?: [NSColor colorWithCalibratedWhite:0.3 alpha:0.45] set];
        
        // get rect
        NSRect myRect = [self objectCounterRectForBounds:frame];
        
        // create badge path
        NSBezierPath *path = [NSBezierPath bezierPathWithRoundedRect:myRect xRadius:kPSMObjectCounterRadius yRadius:kPSMObjectCounterRadius];
        
        // fill badge
		[path fill];

		// draw attributed string centered in area
		NSRect counterStringRect;
		NSAttributedString *counterString = [style attributedObjectCountValueForTabCell:self];
		counterStringRect.size = [counterString size];
		counterStringRect.origin.x = myRect.origin.x + ((myRect.size.width - counterStringRect.size.width) / 2.0) + 0.25;
        counterStringRect.origin.y = NSMidY(myRect)-counterStringRect.size.height/2;
//		counterStringRect.origin.y = myRect.origin.y + ((myRect.size.height - counterStringRect.size.height) / 2.0) +1;//+ 0.5;
		[counterString drawInRect:counterStringRect];    
    
    }
    
}  // -drawObjectCounterWithFrame:inView:

- (void)drawIndicatorWithFrame:(NSRect)frame inView:(NSView *)controlView {

    id <PSMTabStyle> style = [(PSMTabBarControl *)controlView style];
    if ([style respondsToSelector:@selector(drawIndicatorOfTabCell:withFrame:inView:)]) {
        [style drawIndicatorOfTabCell:self withFrame:frame inView:controlView];
    } else {
    
        // we do draw nothing by default
    
    }
    
}  // -drawIndicatorWithFrame:inView:

- (void)drawCloseButtonWithFrame:(NSRect)frame inView:(NSView *)controlView {

    id <PSMTabStyle> style = [(PSMTabBarControl *)controlView style];
    if ([style respondsToSelector:@selector(drawCloseButtonOfTabCell:withFrame:inView:)]) {
        [style drawCloseButtonOfTabCell:self withFrame:frame inView:controlView];
    } else {
    
        // get type of close button to draw
        PSMCloseButtonImageType imageType;
        if ([self isEdited]) {
            if ([self closeButtonOver])
                imageType = PSMCloseButtonImageTypeDirtyRollover;
            else if ([self closeButtonPressed])
                imageType = PSMCloseButtonImageTypeDirtyPressed;
            else
                imageType = PSMCloseButtonImageTypeDirty;
        } else {
            if ([self closeButtonOver])
                imageType = PSMCloseButtonImageTypeRollover;
            else if ([self closeButtonPressed])
                imageType = PSMCloseButtonImageTypePressed;
            else
                imageType = PSMCloseButtonImageTypeStandard;
        }
        
        // ask style for image
        NSImage *image = nil;
        if ([style respondsToSelector:@selector(closeButtonImageOfType:forTabCell:)])
            image = [style closeButtonImageOfType:imageType forTabCell:self];
        // use standard image
        else
            image = [self closeButtonImageOfType:PSMCloseButtonImageTypeStandard];
   
        // draw close button
        NSRect closeButtonRect = [self closeButtonRectForBounds:frame];
    
        [image drawInRect:closeButtonRect fromRect:NSZeroRect operation:NSCompositeSourceOver fraction:1.0];
    }

}  // -drawCloseButtonWithFrame:inView:

#pragma mark -
#pragma mark Tracking

- (void)mouseEntered:(NSEvent *)theEvent {
	// check for which tag
	if([theEvent trackingNumber] == _closeButtonTrackingTag) {
		_closeButtonOver = YES;
	}
	if([theEvent trackingNumber] == _cellTrackingTag) {
		[self setHighlighted:YES];
		[_controlView setNeedsDisplay:NO];
	}

	// scrubtastic
	if([_controlView allowsScrubbing] && ([theEvent modifierFlags] & NSAlternateKeyMask)) {
		[_controlView performSelector:@selector(tabClick:) withObject:self];
	}

	// tell the control we only need to redraw the affected tab
	[_controlView setNeedsDisplayInRect:NSInsetRect([self frame], -2, -2)];
}

- (void)mouseExited:(NSEvent *)theEvent {
	// check for which tag
	if([theEvent trackingNumber] == _closeButtonTrackingTag) {
		_closeButtonOver = NO;
	}

	if([theEvent trackingNumber] == _cellTrackingTag) {
		[self setHighlighted:NO];
		[_controlView setNeedsDisplay:NO];
	}

	//tell the control we only need to redraw the affected tab
	[_controlView setNeedsDisplayInRect:NSInsetRect([self frame], -2, -2)];
}

#pragma mark -
#pragma mark Drag Support

- (NSImage *)dragImage {
	NSRect cellFrame = [(id < PSMTabStyle >)[(PSMTabBarControl *)_controlView style] dragRectForTabCell:self orientation:(PSMTabBarOrientation)[(PSMTabBarControl *)_controlView orientation]];
	//NSRect cellFrame = [self frame];

	[_controlView lockFocus];
	NSBitmapImageRep *rep = [[[NSBitmapImageRep alloc] initWithFocusedViewRect:cellFrame] autorelease];
	[_controlView unlockFocus];
	NSImage *image = [[[NSImage alloc] initWithSize:[rep size]] autorelease];
	[image addRepresentation:rep];
	NSImage *returnImage = [[[NSImage alloc] initWithSize:[rep size]] autorelease];
	[returnImage lockFocus];
    [image drawAtPoint:NSMakePoint(0.0, 0.0) fromRect:NSZeroRect operation:NSCompositeSourceOver fraction:1.0];
	[returnImage unlockFocus];
	if(![[self indicator] isHidden]) {
		NSImage *pi = [[NSImage alloc] initByReferencingFile:[[PSMTabBarControl bundle] pathForImageResource:@"pi"]];
		[returnImage lockFocus];
		NSPoint indicatorPoint = NSMakePoint([self frame].size.width - MARGIN_X - kPSMTabBarIndicatorWidth, MARGIN_Y);
        [pi drawAtPoint:indicatorPoint fromRect:NSZeroRect operation:NSCompositeSourceOver fraction:1.0];
		[returnImage unlockFocus];
		[pi release];
	}
	return returnImage;
}

#pragma mark -
#pragma mark Archiving

- (void)encodeWithCoder:(NSCoder *)aCoder {
	[super encodeWithCoder:aCoder];
	if([aCoder allowsKeyedCoding]) {
		[aCoder encodeRect:_frame forKey:@"frame"];
		[aCoder encodeSize:_stringSize forKey:@"stringSize"];
		[aCoder encodeInteger:_currentStep forKey:@"currentStep"];
		[aCoder encodeBool:_isPlaceholder forKey:@"isPlaceholder"];
		[aCoder encodeInteger:_tabState forKey:@"tabState"];
		[aCoder encodeInteger:_closeButtonTrackingTag forKey:@"closeButtonTrackingTag"];
		[aCoder encodeInteger:_cellTrackingTag forKey:@"cellTrackingTag"];
		[aCoder encodeBool:_closeButtonOver forKey:@"closeButtonOver"];
		[aCoder encodeBool:_closeButtonPressed forKey:@"closeButtonPressed"];
		[aCoder encodeObject:_indicator forKey:@"indicator"];
		[aCoder encodeBool:_isInOverflowMenu forKey:@"isInOverflowMenu"];
		[aCoder encodeBool:_hasCloseButton forKey:@"hasCloseButton"];
		[aCoder encodeBool:_isCloseButtonSuppressed forKey:@"isCloseButtonSuppressed"];
		[aCoder encodeBool:_hasIcon forKey:@"hasIcon"];
		[aCoder encodeBool:_hasLargeImage forKey:@"hasLargeImage"];
		[aCoder encodeInteger:_count forKey:@"count"];
		[aCoder encodeBool:_isEdited forKey:@"isEdited"];
	}
}

- (id)initWithCoder:(NSCoder *)aDecoder {
	self = [super initWithCoder:aDecoder];
	if(self) {
		if([aDecoder allowsKeyedCoding]) {
			_frame = [aDecoder decodeRectForKey:@"frame"];
			_stringSize = [aDecoder decodeSizeForKey:@"stringSize"];
			_currentStep = [aDecoder decodeIntegerForKey:@"currentStep"];
			_isPlaceholder = [aDecoder decodeBoolForKey:@"isPlaceholder"];
			_tabState = [aDecoder decodeIntegerForKey:@"tabState"];
			_closeButtonTrackingTag = [aDecoder decodeIntegerForKey:@"closeButtonTrackingTag"];
			_cellTrackingTag = [aDecoder decodeIntegerForKey:@"cellTrackingTag"];
			_closeButtonOver = [aDecoder decodeBoolForKey:@"closeButtonOver"];
			_closeButtonPressed = [aDecoder decodeBoolForKey:@"closeButtonPressed"];
			_indicator = [[aDecoder decodeObjectForKey:@"indicator"] retain];
			_isInOverflowMenu = [aDecoder decodeBoolForKey:@"isInOverflowMenu"];
			_hasCloseButton = [aDecoder decodeBoolForKey:@"hasCloseButton"];
			_isCloseButtonSuppressed = [aDecoder decodeBoolForKey:@"isCloseButtonSuppressed"];
			_hasIcon = [aDecoder decodeBoolForKey:@"hasIcon"];
			_hasLargeImage = [aDecoder decodeBoolForKey:@"hasLargeImage"];
			_count = [aDecoder decodeIntegerForKey:@"count"];
			_isEdited = [aDecoder decodeBoolForKey:@"isEdited"];
		}
	}
	return self;
}

#pragma mark -
#pragma mark Accessibility

-(BOOL)accessibilityIsIgnored {
	return NO;
}

- (id)accessibilityAttributeValue:(NSString *)attribute {
	id attributeValue = nil;

	if([attribute isEqualToString: NSAccessibilityRoleAttribute]) {
		attributeValue = NSAccessibilityRadioButtonRole;
	} else if([attribute isEqualToString: NSAccessibilityRoleDescriptionAttribute]) {
		attributeValue = NSLocalizedString(@"Tab", nil);
	} else if([attribute isEqualToString: NSAccessibilityTitleAttribute]) {
		attributeValue = [self title];
	} else if([attribute isEqualToString: NSAccessibilityHelpAttribute]) {
		if([[[self controlView] delegate] respondsToSelector:@selector(accessibilityStringForTabView:objectCount:)]) {
			attributeValue = [NSString stringWithFormat:@"%@, %lu %@", [self stringValue],
							  (unsigned long)[self count],
							  [[[self controlView] delegate] accessibilityStringForTabView:[[self controlView] tabView] objectCount:[self count]]];
		} else {
			attributeValue = [self stringValue];
		}
	} else if([attribute isEqualToString: NSAccessibilityFocusedAttribute]) {
		attributeValue = [NSNumber numberWithBool:([self tabState] == 2)];
	} else {
		attributeValue = [super accessibilityAttributeValue:attribute];
	}

	return attributeValue;
}

- (NSArray *)accessibilityActionNames {
	static NSArray *actions;

	if(!actions) {
		actions = [[NSArray alloc] initWithObjects:NSAccessibilityPressAction, nil];
	}
	return actions;
}

- (NSString *)accessibilityActionDescription:(NSString *)action {
	return NSAccessibilityActionDescription(action);
}

- (void)accessibilityPerformAction:(NSString *)action {
	if([action isEqualToString:NSAccessibilityPressAction]) {
		// this tab was selected
		[_controlView performSelector:@selector(tabClick:) withObject:self];
	}
}

- (id)accessibilityHitTest:(NSPoint)point {
	return NSAccessibilityUnignoredAncestor(self);
}

- (id)accessibilityFocusedUIElement:(NSPoint)point {
	return NSAccessibilityUnignoredAncestor(self);
}

@end

@implementation PSMTabBarCell (DEPRECATED)

- (NSRect)indicatorRectForFrame:(NSRect)cellFrame {

    return [self indicatorRectForBounds:cellFrame];
}

- (NSRect)closeButtonRectForFrame:(NSRect)cellFrame {

    return [self closeButtonRectForBounds:cellFrame];
}

@end
