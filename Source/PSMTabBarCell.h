//
//  PSMTabBarCell.h
//  PSMTabBarControl
//
//  Created by John Pannell on 10/13/05.
//  Copyright 2005 Positive Spin Media. All rights reserved.
//

#import <Cocoa/Cocoa.h>
#import "PSMTabBarControl.h"
#import "PSMProgressIndicator.h"

typedef enum PSMCloseButtonImageType : NSUInteger
{
    PSMCloseButtonImageTypeStandard = 0,
    PSMCloseButtonImageTypeRollover,
    PSMCloseButtonImageTypePressed,
    PSMCloseButtonImageTypeDirty,
    PSMCloseButtonImageTypeDirtyRollover,
    PSMCloseButtonImageTypeDirtyPressed
} PSMCloseButtonImageType;

@interface PSMTabBarCell : NSActionCell {
	// sizing
	NSRect					_frame;
	NSSize					_stringSize;
	NSInteger				_currentStep;
	BOOL					_isPlaceholder;

	// state
	NSInteger				_tabState;
	NSTrackingRectTag		_closeButtonTrackingTag; // left side tracking, if dragging
	NSTrackingRectTag		_cellTrackingTag;		 // right side tracking, if dragging
	BOOL					_closeButtonOver;
	BOOL					_closeButtonPressed;
	PSMProgressIndicator	*_indicator;
	BOOL					_isInOverflowMenu;
	BOOL					_hasCloseButton;
	BOOL					_isCloseButtonSuppressed;
	BOOL					_hasIcon;
	BOOL					_hasLargeImage;
	NSInteger				_count;
	NSColor                 *_countColor;
	BOOL					_isEdited;
}

@property (assign) NSInteger tabState;
@property (assign) BOOL hasCloseButton;
@property (assign) BOOL hasIcon;
@property (assign) BOOL hasLargeImage;
@property (assign) NSInteger count;
@property (retain) NSColor *countColor;
@property (assign) BOOL isPlaceholder;
@property (assign) BOOL isEdited;
@property (assign) BOOL closeButtonPressed;
@property (assign) NSTrackingRectTag closeButtonTrackingTag;
@property (assign) NSTrackingRectTag cellTrackingTag;

#pragma mark Creation/Destruction
- (id)initWithControlView:(PSMTabBarControl *)controlView;
- (id)initPlaceholderWithFrame:(NSRect) frame expanded:(BOOL) value inControlView:(PSMTabBarControl *)controlView;
- (void)dealloc;

#pragma mark Accessors
- (id)controlView;
- (void)setControlView:(id)view;
- (NSTrackingRectTag)cellTrackingTag;
- (void)setCellTrackingTag:(NSTrackingRectTag)tag;
- (CGFloat)width;
- (NSRect)frame;
- (void)setFrame:(NSRect)rect;
- (void)setStringValue:(NSString *)aString;
- (NSSize)stringSize;
- (NSAttributedString *)attributedStringValue;
- (NSProgressIndicator *)indicator;
- (BOOL)isInOverflowMenu;
- (void)setIsInOverflowMenu:(BOOL)value;
- (BOOL)closeButtonOver;
- (void)setCloseButtonOver:(BOOL)value;
- (void)setCloseButtonSuppressed:(BOOL)suppress;
- (BOOL)isCloseButtonSuppressed;
- (NSInteger)currentStep;
- (void)setCurrentStep:(NSInteger)value;

#pragma mark Providing Images
- (NSImage *)closeButtonImageOfType:(PSMCloseButtonImageType)type;

#pragma mark Determining Cell Size
- (NSRect)drawingRectForBounds:(NSRect)theRect;
- (NSRect)titleRectForBounds:(NSRect)theRect ;
- (NSRect)iconRectForBounds:(NSRect)theRect;
- (NSRect)largeImageRectForBounds:(NSRect)theRect;
- (NSRect)indicatorRectForBounds:(NSRect)theRect;
- (NSSize)objectCounterSize;
- (NSRect)objectCounterRectForBounds:(NSRect)theRect;
- (NSRect)closeButtonRectForBounds:(NSRect)theRect;

- (CGFloat)minimumWidthOfCell;
- (CGFloat)desiredWidthOfCell;

#pragma mark Image Scaling
- (NSSize)scaleImageWithSize:(NSSize)imageSize toFitInSize:(NSSize)canvasSize scalingType:(NSImageScaling)scalingType;

#pragma mark Drawing
- (BOOL)shouldDrawCloseButton;
- (void)drawWithFrame:(NSRect) cellFrame inView:(NSView *)controlView;
- (void)drawInteriorWithFrame:(NSRect)cellFrame inView:(NSView *)controlView;
- (void)drawLargeImageWithFrame:(NSRect)frame inView:(NSView *)controlView;
- (void)drawIconWithFrame:(NSRect)frame inView:(NSView *)controlView;
- (void)drawTitleWithFrame:(NSRect)frame inView:(NSView *)controlView;
- (void)drawObjectCounterWithFrame:(NSRect)frame inView:(NSView *)controlView;
- (void)drawIndicatorWithFrame:(NSRect)frame inView:(NSView *)controlView;
- (void)drawCloseButtonWithFrame:(NSRect)frame inView:(NSView *)controlView;

#pragma mark Tracking
- (void)mouseEntered:(NSEvent *)theEvent;
- (void)mouseExited:(NSEvent *)theEvent;

#pragma mark Drag Support
- (NSImage *)dragImage;

#pragma mark Archiving
- (void)encodeWithCoder:(NSCoder *)aCoder;
- (id)initWithCoder:(NSCoder *)aDecoder;

@end

@interface PSMTabBarCell (DEPRECATED)

- (NSRect)indicatorRectForFrame:(NSRect)cellFrame DEPRECATED_ATTRIBUTE;
- (NSRect)closeButtonRectForFrame:(NSRect)cellFrame DEPRECATED_ATTRIBUTE;

@end


@interface PSMTabBarControl (CellAccessors)

- (id<PSMTabStyle>)style;

@end

@interface NSObject (IdentifierAccesors)

- (NSImage *)largeImage;

@end


