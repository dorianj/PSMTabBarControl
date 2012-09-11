//
//  PSMTabBarControl.m
//  PSMTabBarControl
//
//  Created by John Pannell on 10/13/05.
//  Copyright 2005 Positive Spin Media. All rights reserved.
//

#import "PSMTabBarControl.h"
#import "PSMTabBarCell.h"
#import "PSMOverflowPopUpButton.h"
#import "PSMRolloverButton.h"
#import "PSMTabStyle.h"
#import "PSMMetalTabStyle.h"
#import "PSMAquaTabStyle.h"
#import "PSMUnifiedTabStyle.h"
#import "PSMAdiumTabStyle.h"
#import "PSMLiveChatTabStyle.h"
#import "PSMCardTabStyle.h"
#import "PSMTabDragAssistant.h"
#import "PSMTabBarController.h"

@interface PSMTabBarControl (/*Private*/)

- (CGFloat)_heightOfTabCells;
- (CGFloat)_rightMargin;
- (CGFloat)_leftMargin;
- (CGFloat)_topMargin;
- (CGFloat)_bottomMargin;
- (NSSize)_addTabButtonSize;
- (NSRect)_addTabButtonRect;
- (NSSize)_overflowButtonSize;
- (NSRect)_overflowButtonRect;
- (void)_drawTabBarControlInRect:(NSRect)aRect;
- (void)_drawBezelInRect:(NSRect)rect;
- (void)_drawInteriorInRect:(NSRect)rect;

@end

@interface PSMTabBarControl (Private)

// constructor/destructor
- (void)initAddedProperties;

// accessors
- (NSEvent *)lastMouseDownEvent;
- (void)setLastMouseDownEvent:(NSEvent *)event;

// contents
- (void)addTabViewItem:(NSTabViewItem *)item;
- (void)addTabViewItem:(NSTabViewItem *)item atIndex:(NSUInteger)index;
- (void)removeTabForCell:(PSMTabBarCell *)cell;

// draw
- (void)update;
- (void)update:(BOOL)animate;
- (void)_positionOverflowMenu;
- (void)_checkWindowFrame;

// actions
- (void)overflowMenuAction:(id)sender;
- (void)closeTabClick:(id)sender;
- (void)tabClick:(id)sender;
- (void)tabNothing:(id)sender;

// notification handlers
- (void)frameDidChange:(NSNotification *)notification;
- (void)windowDidMove:(NSNotification *)aNotification;
- (void)windowDidUpdate:(NSNotification *)notification;

// NSTabView delegate
- (void)tabView:(NSTabView *)tabView didSelectTabViewItem:(NSTabViewItem *)tabViewItem;
- (BOOL)tabView:(NSTabView *)tabView shouldSelectTabViewItem:(NSTabViewItem *)tabViewItem;
- (void)tabView:(NSTabView *)tabView willSelectTabViewItem:(NSTabViewItem *)tabViewItem;
- (void)tabViewDidChangeNumberOfTabViewItems:(NSTabView *)tabView;

// archiving
- (void)encodeWithCoder:(NSCoder *)aCoder;
- (id)initWithCoder:(NSCoder *)aDecoder;

// convenience
- (void)_bindPropertiesForCell:(PSMTabBarCell *)cell andTabViewItem:(NSTabViewItem *)item;
- (id)cellForPoint:(NSPoint)point cellFrame:(NSRectPointer)outFrame;

- (void)_animateCells:(NSTimer *)timer;
@end

@implementation PSMTabBarControl

static NSMutableDictionary *registeredStyleClasses;

+(void)initialize {

    if (registeredStyleClasses == nil) {
        registeredStyleClasses = [[NSMutableDictionary dictionaryWithCapacity:10] retain];
        
        [self registerDefaultTabStyleClasses];
    }
}

#pragma mark -
#pragma mark Characteristics

+ (NSBundle *)bundle;
{
	static NSBundle *bundle = nil;
	if(!bundle) {
		bundle = [NSBundle bundleForClass:[PSMTabBarControl class]];
	}
	return bundle;
}

/*!
    @method     availableCellWidth
    @abstract   The number of pixels available for cells
    @discussion Calculates the number of pixels available for cells based on margins and the window resize badge.
    @returns    Returns the amount of space for cells.
 */

- (CGFloat)availableCellWidth {

    CGFloat result = [self frame].size.width - [self leftMargin] - [self rightMargin];
    
    result -= _resizeAreaCompensation;

	//Don't let cells overlap the add tab button if it is visible
	if ([self showAddTabButton]) {
		result -= [self addTabButtonRect].size.width + 2*kPSMTabBarCellPadding;
	}

    return result;
}

/*!
    @method     availableCellHeight
    @abstract   The number of pixels available for cells
    @discussion Calculates the number of pixels available for cells based on margins and the window resize badge.
    @returns    Returns the amount of space for cells.
 */

- (CGFloat)availableCellHeight {

    CGFloat result = [self bounds].size.height - [self topMargin] - [self bottomMargin];
    
    result -= _resizeAreaCompensation;
        
	//Don't let cells overlap the add tab button if it is visible
	if ([self showAddTabButton]) {
		result -= [self addTabButtonRect].size.height;
	}

	//let room for overflow popup button
    if ([self useOverflowMenu] && ![[self overflowPopUpButton] isHidden]) {
		result -= [self overflowButtonRect].size.height;        
    }
    
    return result;
}

/*!
    @method     genericCellRect
    @abstract   The basic rect for a tab cell.
    @discussion Creates a generic frame for a tab cell based on the current control state.
    @returns    Returns a basic rect for a tab cell.
 */

- (NSRect)genericCellRect {
	NSRect aRect = [self frame];
	aRect.origin.x = [self leftMargin];
	aRect.origin.y = 0.0;
	aRect.size.width = [self availableCellWidth];
	aRect.size.height = [self heightOfTabCells];
	return aRect;
}

- (BOOL)isWindowActive {
    NSWindow *window = [self window];
    BOOL windowActive = NO;
    if ([window isKeyWindow])
        windowActive = YES;
    else if ([window isKindOfClass:[NSPanel class]] && [NSApp isActive])
        windowActive = YES;
    
    return windowActive;
}

#pragma mark -
#pragma mark Constructor/destructor

- (void)initAddedProperties {
	_cells = [[NSMutableArray alloc] initWithCapacity:10];
	_controller = [[PSMTabBarController alloc] initWithTabBarControl:self];
	_animationTimer = nil;

	// default config
	_currentStep = kPSMIsNotBeingResized;
	_orientation = PSMTabBarHorizontalOrientation;
	_canCloseOnlyTab = NO;
	_disableTabClose = NO;
	_showAddTabButton = NO;
	_hideForSingleTab = NO;
	_sizeCellsToFit = NO;
	_isHidden = NO;
	_awakenedFromNib = NO;
	_automaticallyAnimates = NO;
	_useOverflowMenu = YES;
	_allowsBackgroundTabClosing = YES;
	_allowsResizing = NO;
	_selectsTabsOnMouseDown = NO;
	_alwaysShowActiveTab = NO;
	_allowsScrubbing = NO;
	_cellMinWidth = 100;
	_cellMaxWidth = 280;
	_cellOptimumWidth = 130;
	_tearOffStyle = PSMTabBarTearOffAlphaWindow;
	style = [[PSMMetalTabStyle alloc] init];

	// the overflow button/menu
	NSRect overflowButtonRect = [self overflowButtonRect];
	_overflowPopUpButton = [[PSMOverflowPopUpButton alloc] initWithFrame:overflowButtonRect pullsDown:YES];
	[_overflowPopUpButton setAutoresizingMask:NSViewNotSizable | NSViewMinXMargin];
	[_overflowPopUpButton setHidden:YES];
	[self addSubview:_overflowPopUpButton];
	[self _positionOverflowMenu];

	// new tab button
	NSRect addTabButtonRect = [self addTabButtonRect];
	_addTabButton = [[PSMRolloverButton alloc] initWithFrame:addTabButtonRect];
	if(_addTabButton) {
		NSImage *newButtonImage = [style addTabButtonImage];
		if(newButtonImage) {
			[_addTabButton setUsualImage:newButtonImage];
		}
		newButtonImage = [style addTabButtonPressedImage];
		if(newButtonImage) {
			[_addTabButton setAlternateImage:newButtonImage];
		}
		newButtonImage = [style addTabButtonRolloverImage];
		if(newButtonImage) {
			[_addTabButton setRolloverImage:newButtonImage];
		}
		[_addTabButton setTitle:@""];
		[_addTabButton setImagePosition:NSImageOnly];
		[_addTabButton setButtonType:NSMomentaryChangeButton];
		[_addTabButton setBordered:NO];
		[_addTabButton setBezelStyle:NSShadowlessSquareBezelStyle];
		[self addSubview:_addTabButton];

		if(_showAddTabButton) {
			[_addTabButton setHidden:NO];
		} else {
			[_addTabButton setHidden:YES];
		}
		[_addTabButton setNeedsDisplay:YES];
	}
}

- (id)initWithFrame:(NSRect)frame {
	self = [super initWithFrame:frame];
	if(self) {
		// Initialization
		[self initAddedProperties];
		[self registerForDraggedTypes:[NSArray arrayWithObjects:@"PSMTabBarControlItemPBType", nil]];

		// resize
		[self setPostsFrameChangedNotifications:YES];
		[[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(frameDidChange:) name:NSViewFrameDidChangeNotification object:self];
        
        // add observing of cells
        [self addObserver:self forKeyPath:@"cells" options:NSKeyValueObservingOptionNew |
            NSKeyValueObservingOptionOld | NSKeyValueObservingOptionInitial context:NULL];
	}
//	[self setTarget:self];
	return self;
}

- (void)dealloc {
    
    [self removeObserver:self forKeyPath:@"cells"];

	[[NSNotificationCenter defaultCenter] removeObserver:self];

	//stop any animations that may be running
	[_animationTimer invalidate];
	[_animationTimer release]; _animationTimer = nil;

	[_showHideAnimationTimer invalidate];
	[_showHideAnimationTimer release]; _showHideAnimationTimer = nil;

	//Also unwind the spring, if it's wound.
	[_springTimer invalidate];
	[_springTimer release]; _springTimer = nil;

	//unbind all the items to prevent crashing
	//not sure if this is necessary or not
	// http://code.google.com/p/maccode/issues/detail?id=35
    NSArray *tmpCellArray = [_cells copy];
    for (PSMTabBarCell *aCell in tmpCellArray) {
		[self removeTabForCell:aCell];
	}
    [tmpCellArray release];

	[_overflowPopUpButton release];
	[_cells release];
	[_controller release];
	[tabView release];
	[_addTabButton release];
	[partnerView release];
	[_lastMouseDownEvent release];
	[style release];

	[self unregisterDraggedTypes];

	[super dealloc];
}

- (void)awakeFromNib {
	// build cells from existing tab view items
    for (NSTabViewItem *item in [tabView tabViewItems]) {
		if(![[self representedTabViewItems] containsObject:item]) {
			[self addTabViewItem:item];
		}
	}
}

- (void)viewWillMoveToWindow:(NSWindow *)aWindow {
	NSNotificationCenter *center = [NSNotificationCenter defaultCenter];

	[center removeObserver:self name:NSWindowDidBecomeKeyNotification object:nil];
	[center removeObserver:self name:NSWindowDidResignKeyNotification object:nil];
	[center removeObserver:self name:NSWindowDidUpdateNotification object:nil];
	[center removeObserver:self name:NSWindowDidMoveNotification object:nil];

	if(_showHideAnimationTimer) {
		[_showHideAnimationTimer invalidate];
		[_showHideAnimationTimer release]; _showHideAnimationTimer = nil;
	}

	if(aWindow) {
		[center addObserver:self selector:@selector(windowStatusDidChange:) name:NSWindowDidBecomeKeyNotification object:aWindow];
		[center addObserver:self selector:@selector(windowStatusDidChange:) name:NSWindowDidResignKeyNotification object:aWindow];
		[center addObserver:self selector:@selector(windowDidUpdate:) name:NSWindowDidUpdateNotification object:aWindow];
		[center addObserver:self selector:@selector(windowDidMove:) name:NSWindowDidMoveNotification object:aWindow];
	}
}

- (void)windowStatusDidChange:(NSNotification *)notification {
	[self setNeedsDisplay:YES];
}

#pragma mark -
#pragma mark Style Class Registry

+ (void)registerDefaultTabStyleClasses {

    [self registerTabStyleClass:[PSMAquaTabStyle class]];
    [self registerTabStyleClass:[PSMUnifiedTabStyle class]];
    [self registerTabStyleClass:[PSMAdiumTabStyle class]];
    [self registerTabStyleClass:[PSMMetalTabStyle class]];
    [self registerTabStyleClass:[PSMCardTabStyle class]];
    [self registerTabStyleClass:[PSMLiveChatTabStyle class]];
}

+ (void)registerTabStyleClass:(Class <PSMTabStyle>)aStyleClass {
    [registeredStyleClasses setObject:aStyleClass forKey:[aStyleClass name]];
}

+ (void)unregisterTabStyleClass:(Class <PSMTabStyle>)aStyleClass {
    [registeredStyleClasses removeObjectForKey:[aStyleClass name]];
}

+ (NSArray *)registeredTabStyleClasses {
    return [registeredStyleClasses allValues];
}

+ (Class <PSMTabStyle>)registeredClassForStyleName:(NSString *)name {
    return [registeredStyleClasses objectForKey:name];
}

#pragma mark -
#pragma mark Cell Management (KVC Compliant)

- (NSArray *)cells {
    return [[_cells copy] autorelease];
}

// ---- KVC primitives ----

- (void)insertObject:(PSMTabBarCell *)aCell inCellsAtIndex:(NSUInteger)cellIndex {
    [_cells insertObject:aCell atIndex:cellIndex];
}

- (void)insertCells:(NSArray *)aCellArray atIndexes:(NSIndexSet *)indexes {
    [_cells insertObjects:aCellArray atIndexes:indexes];
}

-(void)removeObjectFromCellsAtIndex:(NSUInteger)anIndex {
    [_cells removeObjectAtIndex:anIndex];
}

-(void)removeCellsAtIndexes:(NSIndexSet *)indexes {
    [_cells removeObjectsAtIndexes:indexes];
}

-(void)replaceObjectInCellsAtIndex:(NSUInteger)anIndex withObject:(PSMTabBarCell *)aCell {
    [_cells replaceObjectAtIndex:anIndex withObject:aCell];
}

-(void)replaceCellsAtIndexes:(NSIndexSet *)indexes withCells:(NSArray *)cellArray {
    [_cells replaceObjectsAtIndexes:indexes withObjects:cellArray];
}

// ---- Highlevel methods using KVC compliant primitives ----

- (void)addCell:(PSMTabBarCell *)aCell {
    [self insertObject:aCell inCellsAtIndex:[[self cells] count]];
}

- (void)insertCell:(PSMTabBarCell *)aCell atIndex:(NSUInteger)index {
    [self insertObject:aCell inCellsAtIndex:index];
}

- (void)removeCellAtIndex:(NSUInteger)index {
    [self removeObjectFromCellsAtIndex:index];
}

- (void)replaceCellAtIndex:(NSUInteger)index withCell:(PSMTabBarCell *)aCell {
    [self replaceObjectInCellsAtIndex:index withObject:aCell];
}

#pragma mark -
#pragma mark Displaying a Cell

-(void)updateCell:(NSCell *)aCell {

    if ([aCell isKindOfClass:[PSMTabBarCell class]])
        {
        [self setNeedsDisplayInRect:[(PSMTabBarCell *)aCell frame]];
        }
    else
        [super updateCell:aCell];
}

#pragma mark -
#pragma mark Accessors

- (NSEvent *)lastMouseDownEvent {
	return _lastMouseDownEvent;
}

- (void)setLastMouseDownEvent:(NSEvent *)event {
	[event retain];
	[_lastMouseDownEvent release];
	_lastMouseDownEvent = event;
}

- (id)delegate {
	return delegate;
}

- (void)setDelegate:(id)object {
	delegate = object;

	NSMutableArray *types = [NSMutableArray arrayWithObject:@"PSMTabBarControlItemPBType"];

	//Update the allowed drag types
	if([self delegate] && [[self delegate] respondsToSelector:@selector(allowedDraggedTypesForTabView:)]) {
		[types addObjectsFromArray:[[self delegate] allowedDraggedTypesForTabView:tabView]];
	}
	[self unregisterDraggedTypes];
	[self registerForDraggedTypes:types];
}

- (NSTabView *)tabView {
	return tabView;
}

- (void)setTabView:(NSTabView *)view {
	[view retain];
	[tabView release];
	tabView = view;
}

- (id<PSMTabStyle>)style {
	return style;
}

- (NSString *)styleName {
	return [style name];
}

- (void)setStyle:(id <PSMTabStyle>)newStyle {
	if(style != newStyle) {
		[style autorelease];
		style = [newStyle retain];

		// restyle add tab button
		if(_addTabButton) {
			NSImage *newButtonImage = [style addTabButtonImage];
			if(newButtonImage) {
				[_addTabButton setUsualImage:newButtonImage];
			}

			newButtonImage = [style addTabButtonPressedImage];
			if(newButtonImage) {
				[_addTabButton setAlternateImage:newButtonImage];
			}

			newButtonImage = [style addTabButtonRolloverImage];
			if(newButtonImage) {
				[_addTabButton setRolloverImage:newButtonImage];
			}
		}

		[self update];
	}
}

- (void)setStyleNamed:(NSString *)name {

    Class <PSMTabStyle> styleClass = [[self class] registeredClassForStyleName:name];
    if (styleClass == NULL)
        return;

    id <PSMTabStyle> newStyle = [[(Class)styleClass alloc] init];
	[self setStyle:newStyle];
	[newStyle release];
}

- (PSMTabBarOrientation)orientation {
	return _orientation;
}

- (void)setOrientation:(PSMTabBarOrientation)value {
	PSMTabBarOrientation lastOrientation = _orientation;
	_orientation = value;

	if(_tabBarWidth < 10) {
		_tabBarWidth = 120;
	}

	if(lastOrientation != _orientation) {
		[self _positionOverflowMenu]; //move the overflow popup button to the right place
		[self update:NO];
	}
}

- (BOOL)canCloseOnlyTab {
	return _canCloseOnlyTab;
}

- (void)setCanCloseOnlyTab:(BOOL)value {
	_canCloseOnlyTab = value;
	if([_cells count] == 1) {
		[self update];
	}
}

- (BOOL)disableTabClose {
	return _disableTabClose;
}

- (void)setDisableTabClose:(BOOL)value {
	_disableTabClose = value;
	[self update];
}

- (BOOL)hideForSingleTab {
	return _hideForSingleTab;
}

- (void)setHideForSingleTab:(BOOL)value {
	_hideForSingleTab = value;
	[self update];
}

- (BOOL)showAddTabButton {
	return _showAddTabButton;
}

- (void)setShowAddTabButton:(BOOL)value {
	_showAddTabButton = value;
	if(!NSIsEmptyRect([self addTabButtonRect])) {
		[_addTabButton setFrame:[self addTabButtonRect]];
	}

	[_addTabButton setHidden:!_showAddTabButton];
	[_addTabButton setNeedsDisplay:YES];

	[self update];
}

- (NSInteger)cellMinWidth {
	return _cellMinWidth;
}

- (void)setCellMinWidth:(NSInteger)value {
	_cellMinWidth = value;
	[self update];
}

- (NSInteger)cellMaxWidth {
	return _cellMaxWidth;
}

- (void)setCellMaxWidth:(NSInteger)value {
	_cellMaxWidth = value;
	[self update];
}

- (NSInteger)cellOptimumWidth {
	return _cellOptimumWidth;
}

- (void)setCellOptimumWidth:(NSInteger)value {
	_cellOptimumWidth = value;
	[self update];
}

- (BOOL)sizeCellsToFit {
	return _sizeCellsToFit;
}

- (void)setSizeCellsToFit:(BOOL)value {
	_sizeCellsToFit = value;
	[self update];
}

- (BOOL)useOverflowMenu {
	return _useOverflowMenu;
}

- (void)setUseOverflowMenu:(BOOL)value {
	_useOverflowMenu = value;
	[self update];
}

- (PSMRolloverButton *)addTabButton {
	return _addTabButton;
}

- (PSMOverflowPopUpButton *)overflowPopUpButton {
	return _overflowPopUpButton;
}

- (BOOL)allowsBackgroundTabClosing {
	return _allowsBackgroundTabClosing;
}

- (void)setAllowsBackgroundTabClosing:(BOOL)value {
	_allowsBackgroundTabClosing = value;
}

- (BOOL)allowsResizing {
	return _allowsResizing;
}

- (void)setAllowsResizing:(BOOL)value {
	_allowsResizing = value;
}

- (BOOL)selectsTabsOnMouseDown {
	return _selectsTabsOnMouseDown;
}

- (void)setSelectsTabsOnMouseDown:(BOOL)value {
	_selectsTabsOnMouseDown = value;
}

- (BOOL)automaticallyAnimates {
	return _automaticallyAnimates;
}

- (void)setAutomaticallyAnimates:(BOOL)value {
	_automaticallyAnimates = value;
}

- (BOOL)alwaysShowActiveTab {
	return _alwaysShowActiveTab;
}

- (void)setAlwaysShowActiveTab:(BOOL)value {
	_alwaysShowActiveTab = value;
}

- (BOOL)allowsScrubbing {
	return _allowsScrubbing;
}

- (void)setAllowsScrubbing:(BOOL)value {
	_allowsScrubbing = value;
}

- (PSMTabBarTearOffStyle)tearOffStyle {
	return _tearOffStyle;
}

- (void)setTearOffStyle:(PSMTabBarTearOffStyle)tearOffStyle {
	_tearOffStyle = tearOffStyle;
}

-(CGFloat)heightOfTabCells
{
    if ([style respondsToSelector:@selector(heightOfTabCellsForTabBarControl:)])
        return [style heightOfTabCellsForTabBarControl:self];
    
    return [self _heightOfTabCells];
}

#pragma mark -
#pragma mark Functionality

- (void)addTabViewItem:(NSTabViewItem *)item atIndex:(NSUInteger)index {
	// create cell
	PSMTabBarCell *cell = [[PSMTabBarCell alloc] init];
    [cell setControlView:self];
	NSRect cellRect = NSZeroRect, lastCellFrame = NSZeroRect;
	if([_cells lastObject] != nil) {
		lastCellFrame = [[_cells lastObject] frame];
	}

	if([self orientation] == PSMTabBarHorizontalOrientation) {
		cellRect = [self genericCellRect];
		cellRect.size.width = 30;
		cellRect.origin.x = lastCellFrame.origin.x + lastCellFrame.size.width;
	} else {
		cellRect = /*lastCellFrame*/ [self genericCellRect];
		cellRect.size.width = lastCellFrame.size.width;
		cellRect.size.height = 0;
		cellRect.origin.y = lastCellFrame.origin.y + lastCellFrame.size.height;
	}

	[cell setRepresentedObject:item];
	[cell setFrame:cellRect];

	// bind it up
	[self bindPropertiesForCell:cell andTabViewItem:item];

	// add to collection
    [self insertCell:cell atIndex:index];
	[cell release];
	if([_cells count] == [tabView numberOfTabViewItems]) {
		[self update]; // don't update unless all are accounted for!
	}
}

- (void)addTabViewItem:(NSTabViewItem *)item {
  [self addTabViewItem:item atIndex:[_cells count]];
}

- (void)removeTabForCell:(PSMTabBarCell *)cell {
	NSTabViewItem *item = [cell representedObject];

	// unbind
	[[cell indicator] unbind:@"animate"];
	[[cell indicator] unbind:@"hidden"];
	[cell unbind:@"hasIcon"];
	[cell unbind:@"hasLargeImage"];
	[cell unbind:@"title"];
	[cell unbind:@"count"];
	[cell unbind:@"countColor"];
	[cell unbind:@"isEdited"];

	if([item identifier] != nil) {
		if([[item identifier] respondsToSelector:@selector(isProcessing)]) {
			[[item identifier] removeObserver:cell forKeyPath:@"isProcessing"];
		}
	}

	if([item identifier] != nil) {
		if([[item identifier] respondsToSelector:@selector(icon)]) {
			[[item identifier] removeObserver:cell forKeyPath:@"icon"];
		}
	}

	if([item identifier] != nil) {
		if([[item identifier] respondsToSelector:@selector(objectCount)]) {
			[[item identifier] removeObserver:cell forKeyPath:@"objectCount"];
		}
	}

	if([item identifier] != nil) {
		if([[item identifier] respondsToSelector:@selector(countColor)]) {
			[[item identifier] removeObserver:cell forKeyPath:@"countColor"];
		}
	}

	if([item identifier] != nil) {
		if([[item identifier] respondsToSelector:@selector(largeImage)]) {
			[[item identifier] removeObserver:cell forKeyPath:@"largeImage"];
		}
	}

	if([item identifier] != nil) {
		if([[item identifier] respondsToSelector:@selector(isEdited)]) {
			[[item identifier] removeObserver:cell forKeyPath:@"isEdited"];
		}
	}

	// stop watching identifier
	@try {
		[item removeObserver:self forKeyPath:@"identifier"];
	}
	@catch (NSException *exception) {
	}	

	// remove indicator
	if([[self subviews] containsObject:[cell indicator]]) {
		[[cell indicator] removeFromSuperview];
	}
	// remove tracking
	[[NSNotificationCenter defaultCenter] removeObserver:cell];

	// pull from collection
    NSUInteger cellIndex = [_cells indexOfObjectIdenticalTo:cell];
    if (cellIndex != NSNotFound)
        [self removeCellAtIndex:cellIndex];

	[self update];
}

- (void)observeValueForKeyPath:(NSString *)keyPath ofObject:(id)object change:(NSDictionary *)change context:(void *)context {

    // did cell array change?
    if ([keyPath isEqualToString:@"cells"]) {
        [self updateTrackingAreas];

    // did the tab's identifier change?
    } else if([keyPath isEqualToString:@"identifier"]) {
        id oldIdentifier = [change objectForKey: NSKeyValueChangeOldKey];
        
        for (PSMTabBarCell *cell in _cells) {
            if([cell representedObject] == object) {
                // unbind the old value first
                NSArray *selectors = [NSArray arrayWithObjects: @"isProcessing", @"icon", @"objectCount", @"countColor", @"largeImage", @"isEdited", nil];
                for (NSString *selector in selectors) {
                    if([oldIdentifier respondsToSelector: NSSelectorFromString(selector)]) {
                        [oldIdentifier unbind: selector];
                        [oldIdentifier removeObserver:cell forKeyPath:selector];
                    }
                }
                [self _bindPropertiesForCell:cell andTabViewItem:object];
            }
        }
    } else {
        [super observeValueForKeyPath:keyPath ofObject:object change:change context:context];
    }
}

#pragma mark -
#pragma mark Hide/Show

- (void)hideTabBar:(BOOL)hide animate:(BOOL)animate {
	if(!_awakenedFromNib || (_isHidden && hide) || (!_isHidden && !hide) || (_currentStep != kPSMIsNotBeingResized)) {
		return;
	}

	[[self subviews] makeObjectsPerformSelector:@selector(removeFromSuperview)];

	_isHidden = hide;
	_currentStep = 0;
	if(!animate) {
		_currentStep = (NSInteger)kPSMHideAnimationSteps;
	}

	if(hide) {
		[_overflowPopUpButton removeFromSuperview];
		[_addTabButton removeFromSuperview];
	} else if(!animate) {
		[self addSubview:_overflowPopUpButton];
		[self addSubview:_addTabButton];
	}

	CGFloat partnerOriginalSize, partnerOriginalOrigin, myOriginalSize, myOriginalOrigin, partnerTargetSize, partnerTargetOrigin, myTargetSize, myTargetOrigin;

	// target values for partner
	if([self orientation] == PSMTabBarHorizontalOrientation) {
		// current (original) values
		myOriginalSize = [self frame].size.height;
		myOriginalOrigin = [self frame].origin.y;
		if(partnerView) {
			partnerOriginalSize = [partnerView frame].size.height;
			partnerOriginalOrigin = [partnerView frame].origin.y;
		} else {
			partnerOriginalSize = [[self window] frame].size.height;
			partnerOriginalOrigin = [[self window] frame].origin.y;
		}

		if(partnerView) {
			// above or below me?
			if((myOriginalOrigin - 22) > partnerOriginalOrigin) {
				// partner is below me
				if(_isHidden) {
					// I'm shrinking
					myTargetOrigin = myOriginalOrigin + 21;
					myTargetSize = myOriginalSize - 21;
					partnerTargetOrigin = partnerOriginalOrigin;
					partnerTargetSize = partnerOriginalSize + 21;
				} else {
					// I'm growing
					myTargetOrigin = myOriginalOrigin - 21;
					myTargetSize = myOriginalSize + 21;
					partnerTargetOrigin = partnerOriginalOrigin;
					partnerTargetSize = partnerOriginalSize - 21;
				}
			} else {
				// partner is above me
				if(_isHidden) {
					// I'm shrinking
					myTargetOrigin = myOriginalOrigin;
					myTargetSize = myOriginalSize - 21;
					partnerTargetOrigin = partnerOriginalOrigin - 21;
					partnerTargetSize = partnerOriginalSize + 21;
				} else {
					// I'm growing
					myTargetOrigin = myOriginalOrigin;
					myTargetSize = myOriginalSize + 21;
					partnerTargetOrigin = partnerOriginalOrigin + 21;
					partnerTargetSize = partnerOriginalSize - 21;
				}
			}
		} else {
			// for window movement
			if(_isHidden) {
				// I'm shrinking
				myTargetOrigin = myOriginalOrigin;
				myTargetSize = myOriginalSize - 21;
				partnerTargetOrigin = partnerOriginalOrigin + 21;
				partnerTargetSize = partnerOriginalSize - 21;
			} else {
				// I'm growing
				myTargetOrigin = myOriginalOrigin;
				myTargetSize = myOriginalSize + 21;
				partnerTargetOrigin = partnerOriginalOrigin - 21;
				partnerTargetSize = partnerOriginalSize + 21;
			}
		}
	} else {   /* vertical */
		       // current (original) values
		myOriginalSize = [self frame].size.width;
		myOriginalOrigin = [self frame].origin.x;
		if(partnerView) {
			partnerOriginalSize = [partnerView frame].size.width;
			partnerOriginalOrigin = [partnerView frame].origin.x;
		} else {
			partnerOriginalSize = [[self window] frame].size.width;
			partnerOriginalOrigin = [[self window] frame].origin.x;
		}

		if(partnerView) {
			//to the left or right?
			if(myOriginalOrigin < partnerOriginalOrigin + partnerOriginalSize) {
				// partner is to the left
				if(_isHidden) {
					// I'm shrinking
					myTargetOrigin = myOriginalOrigin;
					myTargetSize = 1;
					partnerTargetOrigin = partnerOriginalOrigin - myOriginalSize + 1;
					partnerTargetSize = partnerOriginalSize + myOriginalSize - 1;
					_tabBarWidth = myOriginalSize;
				} else {
					// I'm growing
					myTargetOrigin = myOriginalOrigin;
					myTargetSize = myOriginalSize + _tabBarWidth;
					partnerTargetOrigin = partnerOriginalOrigin + _tabBarWidth;
					partnerTargetSize = partnerOriginalSize - _tabBarWidth;
				}
			} else {
				// partner is to the right
				if(_isHidden) {
					// I'm shrinking
					myTargetOrigin = myOriginalOrigin + myOriginalSize;
					myTargetSize = 1;
					partnerTargetOrigin = partnerOriginalOrigin;
					partnerTargetSize = partnerOriginalSize + myOriginalSize;
					_tabBarWidth = myOriginalSize;
				} else {
					// I'm growing
					myTargetOrigin = myOriginalOrigin - _tabBarWidth;
					myTargetSize = myOriginalSize + _tabBarWidth;
					partnerTargetOrigin = partnerOriginalOrigin;
					partnerTargetSize = partnerOriginalSize - _tabBarWidth;
				}
			}
		} else {
			// for window movement
			if(_isHidden) {
				// I'm shrinking
				myTargetOrigin = myOriginalOrigin;
				myTargetSize = 1;
				partnerTargetOrigin = partnerOriginalOrigin + myOriginalSize - 1;
				partnerTargetSize = partnerOriginalSize - myOriginalSize + 1;
				_tabBarWidth = myOriginalSize;
			} else {
				// I'm growing
				myTargetOrigin = myOriginalOrigin;
				myTargetSize = _tabBarWidth;
				partnerTargetOrigin = partnerOriginalOrigin - _tabBarWidth + 1;
				partnerTargetSize = partnerOriginalSize + _tabBarWidth - 1;
			}
		}

		if(!_isHidden && [[self delegate] respondsToSelector:@selector(desiredWidthForVerticalTabBar:)]) {
			myTargetSize = [[self delegate] desiredWidthForVerticalTabBar:self];
		}
	}

	NSDictionary *userInfo = [NSDictionary dictionaryWithObjectsAndKeys:[NSNumber numberWithDouble:myOriginalOrigin], @"myOriginalOrigin", [NSNumber numberWithDouble:partnerOriginalOrigin], @"partnerOriginalOrigin", [NSNumber numberWithDouble:myOriginalSize], @"myOriginalSize", [NSNumber numberWithDouble:partnerOriginalSize], @"partnerOriginalSize", [NSNumber numberWithDouble:myTargetOrigin], @"myTargetOrigin", [NSNumber numberWithDouble:partnerTargetOrigin], @"partnerTargetOrigin", [NSNumber numberWithDouble:myTargetSize], @"myTargetSize", [NSNumber numberWithDouble:partnerTargetSize], @"partnerTargetSize", nil];
	if(_showHideAnimationTimer) {
		[_showHideAnimationTimer invalidate];
		[_showHideAnimationTimer release];
	}
	_showHideAnimationTimer = [[NSTimer scheduledTimerWithTimeInterval:(1.0 / 30.0) target:self selector:@selector(animateShowHide:) userInfo:userInfo repeats:YES] retain];
}

- (void)animateShowHide:(NSTimer *)timer {
	// moves the frame of the tab bar and window (or partner view) linearly to hide or show the tab bar
	NSRect myFrame = [self frame];
	NSDictionary *userInfo = [timer userInfo];
	CGFloat myCurrentOrigin = ([[userInfo objectForKey:@"myOriginalOrigin"] doubleValue] + (([[userInfo objectForKey:@"myTargetOrigin"] doubleValue] - [[userInfo objectForKey:@"myOriginalOrigin"] doubleValue]) * (_currentStep / kPSMHideAnimationSteps)));
	CGFloat myCurrentSize = ([[userInfo objectForKey:@"myOriginalSize"] doubleValue] + (([[userInfo objectForKey:@"myTargetSize"] doubleValue] - [[userInfo objectForKey:@"myOriginalSize"] doubleValue]) * (_currentStep / kPSMHideAnimationSteps)));
	CGFloat partnerCurrentOrigin = ([[userInfo objectForKey:@"partnerOriginalOrigin"] doubleValue] + (([[userInfo objectForKey:@"partnerTargetOrigin"] doubleValue] - [[userInfo objectForKey:@"partnerOriginalOrigin"] doubleValue]) * (_currentStep / kPSMHideAnimationSteps)));
	CGFloat partnerCurrentSize = ([[userInfo objectForKey:@"partnerOriginalSize"] doubleValue] + (([[userInfo objectForKey:@"partnerTargetSize"] doubleValue] - [[userInfo objectForKey:@"partnerOriginalSize"] doubleValue]) * (_currentStep / kPSMHideAnimationSteps)));

	NSRect myNewFrame;
	if([self orientation] == PSMTabBarHorizontalOrientation) {
		myNewFrame = NSMakeRect(myFrame.origin.x, myCurrentOrigin, myFrame.size.width, myCurrentSize);
	} else {
		myNewFrame = NSMakeRect(myCurrentOrigin, myFrame.origin.y, myCurrentSize, myFrame.size.height);
	}

	if(partnerView) {
		// resize self and view
		NSRect resizeRect;
		if([self orientation] == PSMTabBarHorizontalOrientation) {
			resizeRect = NSMakeRect([partnerView frame].origin.x, partnerCurrentOrigin, [partnerView frame].size.width, partnerCurrentSize);
		} else {
			resizeRect = NSMakeRect(partnerCurrentOrigin, [partnerView frame].origin.y, partnerCurrentSize, [partnerView frame].size.height);
		}
		[partnerView setFrame:resizeRect];
		[partnerView setNeedsDisplay:YES];
		[self setFrame:myNewFrame];
	} else {
		// resize self and window
		NSRect resizeRect;
		if([self orientation] == PSMTabBarHorizontalOrientation) {
			resizeRect = NSMakeRect([[self window] frame].origin.x, partnerCurrentOrigin, [[self window] frame].size.width, partnerCurrentSize);
		} else {
			resizeRect = NSMakeRect(partnerCurrentOrigin, [[self window] frame].origin.y, partnerCurrentSize, [[self window] frame].size.height);
		}
		[[self window] setFrame:resizeRect display:YES];
		[self setFrame:myNewFrame];
	}

	// next
	_currentStep++;
	if(_currentStep == kPSMHideAnimationSteps + 1) {
		_currentStep = kPSMIsNotBeingResized;
		[self viewDidEndLiveResize];
		[self update:NO];

		//send the delegate messages
		if(_isHidden) {
			if([[self delegate] respondsToSelector:@selector(tabView:tabBarDidHide:)]) {
				[[self delegate] tabView:[self tabView] tabBarDidHide:self];
			}
		} else {
			[self addSubview:_overflowPopUpButton];
			[self addSubview:_addTabButton];

			if([[self delegate] respondsToSelector:@selector(tabView:tabBarDidUnhide:)]) {
				[[self delegate] tabView:[self tabView] tabBarDidUnhide:self];
			}
		}

		[_showHideAnimationTimer invalidate];
		[_showHideAnimationTimer release]; _showHideAnimationTimer = nil;
	}
	[[self window] display];
}

- (BOOL)isTabBarHidden {
	return _isHidden;
}

- (BOOL)isAnimating {
	return _animationTimer != nil;
}

- (id)partnerView {
	return partnerView;
}

- (void)setPartnerView:(id)view {
	[partnerView release];
	[view retain];
	partnerView = view;
}

#pragma mark -
#pragma mark Determining Sizes

- (NSSize)addTabButtonSize {

    NSSize theSize;
    
    if ([style respondsToSelector:@selector(addTabButtonSizeForTabBarControl:)]) {
        theSize = [style addTabButtonSizeForTabBarControl:self];
    } else {
        theSize = [self _addTabButtonSize];
    }

    return theSize;
}

- (NSRect)addTabButtonRect {
    
    NSRect theRect;
    
    if ([style respondsToSelector:@selector(addTabButtonRectForTabBarControl:)]) {
        theRect = [style addTabButtonRectForTabBarControl:self];
    } else {
        theRect = [self _addTabButtonRect];
    }

    return theRect;
}

- (NSSize)overflowButtonSize {

    NSSize theSize;
    
    if ([style respondsToSelector:@selector(overflowButtonSizeForTabBarControl:)]) {
        theSize = [style overflowButtonSizeForTabBarControl:self];
    } else {
        theSize = [self _overflowButtonSize];
    }

    return theSize;
}

- (NSRect)overflowButtonRect {

    NSRect theRect;
    
    if ([style respondsToSelector:@selector(overflowButtonRectForTabBarControl:)]) {
        theRect = [style overflowButtonRectForTabBarControl:self];
    } else {
        theRect = [self _overflowButtonRect];
    }

    return theRect;
}

#pragma mark -
#pragma mark Determining Margins

- (CGFloat)rightMargin {
    CGFloat margin = 0.0;
    
    if ([style respondsToSelector:@selector(rightMarginForTabBarControl:)]) {
        margin = [style rightMarginForTabBarControl:self];
    } else {
        margin = [self _rightMargin];
    }

    return margin;
}

- (CGFloat)leftMargin {
    CGFloat margin = 0.0;
    
    if ([style respondsToSelector:@selector(leftMarginForTabBarControl:)]) {
        margin = [style leftMarginForTabBarControl:self];
    } else {
        margin = [self _leftMargin];
    }

    return margin;
}

- (CGFloat)topMargin {
    CGFloat margin = 0.0;
    
    if ([style respondsToSelector:@selector(topMarginForTabBarControl:)]) {
        margin = [style topMarginForTabBarControl:self];
    } else {
        margin = [self _topMargin];
    }

    return margin;
}

- (CGFloat)bottomMargin {
    CGFloat margin = 0.0;
    
    if ([style respondsToSelector:@selector(bottomMarginForTabBarControl:)]) {
        margin = [style bottomMarginForTabBarControl:self];
    } else {
        margin = [self _bottomMargin];
    }

    return margin;
}

#pragma mark -
#pragma mark Drawing

- (BOOL)isFlipped {
	return YES;
}

- (void)drawRect:(NSRect)rect {

    if ([style respondsToSelector:@selector(drawTabBarControl:inRect:)]) {
        [style drawTabBarControl:self inRect:rect];
    } else {
        [self _drawTabBarControlInRect:rect];
    }
}

- (void)drawBezelInRect:(NSRect)rect {

    if ([style respondsToSelector:@selector(drawBezelOfTabBarControl:inRect:)]) {
        [style drawBezelOfTabBarControl:self inRect:rect];
    } else {
        [self _drawBezelInRect:rect];
    }    
}

- (void)drawInteriorInRect:(NSRect)rect {
    if ([style respondsToSelector:@selector(drawInteriorOfTabBarControl:inRect:)]) {
        [style drawInteriorOfTabBarControl:self inRect:rect];
    } else {
        [self _drawInteriorInRect:rect];
    }
}

- (void)update {
	[self update:_automaticallyAnimates];
}

- (void)update:(BOOL)animate {
	// make sure all of our tabs are accounted for before updating
	if([[self tabView] numberOfTabViewItems] != [_cells count]) {
		return;
	}

	// hide/show? (these return if already in desired state)
	if((_hideForSingleTab) && ([_cells count] <= 1)) {
		[self hideTabBar:YES animate:YES];
		return;
	} else {
		[self hideTabBar:NO animate:YES];
	}

	[self removeAllToolTips];
	[_controller layoutCells]; //eventually we should only have to call this when we know something has changed

	PSMTabBarCell *currentCell;

	NSMenu *overflowMenu = [_controller overflowMenu];
	[_overflowPopUpButton setHidden:(overflowMenu == nil)];
	[_overflowPopUpButton setMenu:overflowMenu];
    [self _positionOverflowMenu];        

	if(_animationTimer) {
		[_animationTimer invalidate];
		[_animationTimer release]; _animationTimer = nil;
	}

	if(animate) {
		NSMutableArray *targetFrames = [NSMutableArray arrayWithCapacity:[_cells count]];

		for(NSInteger i = 0; i < [_cells count]; i++) {
			//we're going from NSRect -> NSValue -> NSRect -> NSValue here - oh well
			[targetFrames addObject:[NSValue valueWithRect:[_controller cellFrameAtIndex:i]]];
		}

		[_addTabButton setHidden:!_showAddTabButton];

		NSAnimation *animation = [[NSAnimation alloc] initWithDuration:0.50 animationCurve:NSAnimationEaseInOut];
		[animation setAnimationBlockingMode:NSAnimationNonblocking];
		[animation startAnimation];
		_animationTimer = [[NSTimer scheduledTimerWithTimeInterval:1.0 / 30.0
							target:self
							selector:@selector(_animateCells:)
							userInfo:[NSArray arrayWithObjects:targetFrames, animation, nil]
							repeats:YES] retain];
		[animation release];
		[[NSRunLoop currentRunLoop] addTimer:_animationTimer forMode:NSEventTrackingRunLoopMode];
		[self _animateCells:_animationTimer];
	} else {
		for(NSInteger i = 0; i < [_cells count]; i++) {
			currentCell = [_cells objectAtIndex:i];
			[currentCell setFrame:[_controller cellFrameAtIndex:i]];
		}

		[_addTabButton setFrame:[self addTabButtonRect]];
		[_addTabButton setHidden:!_showAddTabButton];
        [self updateTrackingAreas];
		[self setNeedsDisplay:YES];
	}
}

- (void)_animateCells:(NSTimer *)timer {
	NSAnimation *animation = [[timer userInfo] objectAtIndex:1];
	NSArray *targetFrames = [[timer userInfo] objectAtIndex:0];
	PSMTabBarCell *currentCell;
	NSInteger cellCount = [_cells count];

	if((cellCount > 0) && [animation isAnimating]) {
		//compare our target position with the current position and move towards the target
		for(NSInteger i = 0; i < [targetFrames count] && i < cellCount; i++) {
			currentCell = [_cells objectAtIndex:i];
			NSRect cellFrame = [currentCell frame], targetFrame = [[targetFrames objectAtIndex:i] rectValue];
			CGFloat sizeChange;
			CGFloat originChange;

			if([self orientation] == PSMTabBarHorizontalOrientation) {
				sizeChange = (targetFrame.size.width - cellFrame.size.width) * [animation currentProgress];
				originChange = (targetFrame.origin.x - cellFrame.origin.x) * [animation currentProgress];
				cellFrame.size.width += sizeChange;
				cellFrame.origin.x += originChange;
			} else {
				sizeChange = (targetFrame.size.height - cellFrame.size.height) * [animation currentProgress];
				originChange = (targetFrame.origin.y - cellFrame.origin.y) * [animation currentProgress];
				cellFrame.size.height += sizeChange;
				cellFrame.origin.y += originChange;
			}

			[currentCell setFrame:cellFrame];

			//highlight the cell if the mouse is over it
			NSPoint mousePoint = [self convertPoint:[[self window] mouseLocationOutsideOfEventStream] fromView:nil];
			NSRect closeRect = [currentCell closeButtonRectForBounds:cellFrame];
			[currentCell setHighlighted:NSMouseInRect(mousePoint, cellFrame, [self isFlipped])];
			[currentCell setCloseButtonOver:NSMouseInRect(mousePoint, closeRect, [self isFlipped])];
		}

		if(_showAddTabButton) {
			//animate the add tab button
			NSRect target = [self addTabButtonRect], frame = [_addTabButton frame];
			frame.origin.x += (target.origin.x - frame.origin.x) * [animation currentProgress];
			frame.origin.y += (target.origin.y - frame.origin.y) * [animation currentProgress]            ;
			[_addTabButton setFrame:frame];
		}
	} else {
		//put all the cells where they should be in their final position
		if(cellCount > 0) {
			for(NSInteger i = 0; i < [targetFrames count] && i < cellCount; i++) {
				PSMTabBarCell *currentCell = [_cells objectAtIndex:i];
				NSRect cellFrame = [currentCell frame], targetFrame = [[targetFrames objectAtIndex:i] rectValue];

				if([self orientation] == PSMTabBarHorizontalOrientation) {
					cellFrame.size.width = targetFrame.size.width;
					cellFrame.origin.x = targetFrame.origin.x;
				} else {
					cellFrame.size.height = targetFrame.size.height;
					cellFrame.origin.y = targetFrame.origin.y;
				}

				[currentCell setFrame:cellFrame];

				//highlight the cell if the mouse is over it
				NSPoint mousePoint = [self convertPoint:[[self window] mouseLocationOutsideOfEventStream] fromView:nil];
				NSRect closeRect = [currentCell closeButtonRectForBounds:cellFrame];
				[currentCell setHighlighted:NSMouseInRect(mousePoint, cellFrame, [self isFlipped])];
				[currentCell setCloseButtonOver:NSMouseInRect(mousePoint, closeRect, [self isFlipped])];
			}
		}

		//set the frame for the add tab button
		if(_showAddTabButton) {
            [_addTabButton setFrame:[self addTabButtonRect]];
		}

		[_animationTimer invalidate];
		[_animationTimer release]; _animationTimer = nil;

        [self updateTrackingAreas];
	}

	[self setNeedsDisplay:YES];
}

- (void)_positionOverflowMenu {

    NSRect buttonRect = [self overflowButtonRect];
    if (!NSEqualRects(buttonRect, NSZeroRect))
        [_overflowPopUpButton setFrame:buttonRect];
}

- (void)_checkWindowFrame {
	//figure out if the new frame puts the control in the way of the resize widget
	NSWindow *window = [self window];

	if(window) {
		NSRect resizeWidgetFrame = [[window contentView] frame];
		resizeWidgetFrame.origin.x += resizeWidgetFrame.size.width - 22;
		resizeWidgetFrame.size.width = 22;
		resizeWidgetFrame.size.height = 22;

		if([window showsResizeIndicator] && NSIntersectsRect([self frame], resizeWidgetFrame)) {
			//the resize widgets are larger on metal windows
			_resizeAreaCompensation = [window styleMask] & NSTexturedBackgroundWindowMask ? 20 : 8;
		} else {
			_resizeAreaCompensation = 0;
		}
	}
}

#pragma mark -
#pragma mark Tracking Area Support

- (void)updateTrackingAreas {

    [super updateTrackingAreas];
    
    // remove all tracking rects
    for (NSTrackingArea *area in [self trackingAreas]) {
        // We have to uniquely identify our own tracking areas
        if ([area owner] == self) {
            [self removeTrackingArea:area];
        }
    }

    // remove all tool tip rects
    [self removeAllToolTips];
    
    // recreate tracking areas and tool tip rects
    NSPoint mouseLocation = [self convertPoint:[[self window] convertScreenToBase:[NSEvent mouseLocation]] fromView:nil];
    
    NSUInteger cellIndex = 0;
    for (PSMTabBarCell *aCell in _cells) {
    
        if ([aCell isInOverflowMenu])
            break;
    
        NSDictionary *userInfo = [NSDictionary dictionaryWithObjectsAndKeys:[NSNumber numberWithInteger:cellIndex], @"cellIndex", aCell, @"cell", nil];
        [aCell addTrackingAreasForView:self inRect:[aCell frame] withUserInfo:userInfo mouseLocation:mouseLocation];

        [self addToolTipRect:[aCell frame] owner:self userData:nil];
        
        cellIndex ++;
    }
}

- (void)mouseEntered:(NSEvent *)theEvent {

    if ([[theEvent trackingArea] owner] == self) {
        NSDictionary *userInfo = [theEvent userData];
        PSMTabBarCell *tabBarCell = [userInfo objectForKey:@"cell"];
        if (tabBarCell)
            [tabBarCell mouseEntered:theEvent];    
    }
        
}

- (void)mouseExited:(NSEvent *)theEvent {

    if ([[theEvent trackingArea] owner] == self) {
        NSDictionary *userInfo = [theEvent userData];
        PSMTabBarCell *tabBarCell = [userInfo objectForKey:@"cell"];
        if (tabBarCell)
            [tabBarCell mouseExited:theEvent];
    }
}

#pragma mark -
#pragma mark Mouse Tracking

- (BOOL)mouseDownCanMoveWindow {
	return NO;
}

- (BOOL)acceptsFirstMouse:(NSEvent *)theEvent {
	return YES;
}

- (void)mouseDown:(NSEvent *)theEvent {
	_didDrag = NO;

	// keep for dragging
	[self setLastMouseDownEvent:theEvent];
	// what cell?
	NSPoint mousePt = [self convertPoint:[theEvent locationInWindow] fromView:nil];
	NSRect frame = [self frame];

	if([self orientation] == PSMTabBarVerticalOrientation && [self allowsResizing] && partnerView && (mousePt.x > frame.size.width - 3)) {
		_resizing = YES;
	}

	NSRect cellFrame;
	PSMTabBarCell *cell = [self cellForPoint:mousePt cellFrame:&cellFrame];
	if(cell) {
		BOOL overClose = NSMouseInRect(mousePt, [cell closeButtonRectForBounds:cellFrame], [self isFlipped]);
		if(overClose &&
		   ![self disableTabClose] &&
		   ![cell isCloseButtonSuppressed] &&
		   ([self allowsBackgroundTabClosing] || [[cell representedObject] isEqualTo:[tabView selectedTabViewItem]] || [theEvent modifierFlags] & NSCommandKeyMask)) {
			[cell setCloseButtonOver:NO];
			[cell setCloseButtonPressed:YES];
			_closeClicked = YES;
		} else {
			[cell setCloseButtonPressed:NO];
			if(_selectsTabsOnMouseDown || _tearOffStyle == PSMTabBarTearOffMiniwindow) {
				[self performSelector:@selector(tabClick:) withObject:cell];
			}
		}
		[self setNeedsDisplay:YES];
	}
}

- (void)mouseDragged:(NSEvent *)theEvent {
	if([self lastMouseDownEvent] == nil) {
		return;
	}

	NSPoint currentPoint = [self convertPoint:[theEvent locationInWindow] fromView:nil];

	if(_resizing) {
		NSRect frame = [self frame];
		CGFloat resizeAmount = [theEvent deltaX];
		if((currentPoint.x > frame.size.width && resizeAmount > 0) || (currentPoint.x < frame.size.width && resizeAmount < 0)) {
			[[NSCursor resizeLeftRightCursor] push];

			NSRect partnerFrame = [partnerView frame];

			//do some bounds checking
			if((frame.size.width + resizeAmount > [self cellMinWidth]) && (frame.size.width + resizeAmount < [self cellMaxWidth])) {
				frame.size.width += resizeAmount;
				partnerFrame.size.width -= resizeAmount;
				partnerFrame.origin.x += resizeAmount;

				[self setFrame:frame];
				[partnerView setFrame:partnerFrame];
				[[self superview] setNeedsDisplay:YES];
			}
		}
		return;
	}

	NSRect cellFrame;
	NSPoint trackingStartPoint = [self convertPoint:[[self lastMouseDownEvent] locationInWindow] fromView:nil];
	PSMTabBarCell *cell = [self cellForPoint:trackingStartPoint cellFrame:&cellFrame];
	if(cell) {
		//check to see if the close button was the target in the clicked cell
		//highlight/unhighlight the close button as necessary
		NSRect iconRect = [cell closeButtonRectForBounds:cellFrame];

		if(_closeClicked && NSMouseInRect(trackingStartPoint, iconRect, [self isFlipped]) &&
		   ([self allowsBackgroundTabClosing] || [[cell representedObject] isEqualTo:[tabView selectedTabViewItem]])) {
			[cell setCloseButtonPressed:NSMouseInRect(currentPoint, iconRect, [self isFlipped])];
			[self setNeedsDisplay:YES];
			return;
		}

		CGFloat dx = fabs(currentPoint.x - trackingStartPoint.x);
		CGFloat dy = fabs(currentPoint.y - trackingStartPoint.y);
		CGFloat distance = sqrt(dx * dx + dy * dy);

		if(distance >= 10 && !_didDrag && ![[PSMTabDragAssistant sharedDragAssistant] isDragging] &&
		   [self delegate] && [[self delegate] respondsToSelector:@selector(tabView:shouldDragTabViewItem:fromTabBar:)] &&
		   [[self delegate] tabView:tabView shouldDragTabViewItem:[cell representedObject] fromTabBar:self]) {
			_didDrag = YES;
			[[PSMTabDragAssistant sharedDragAssistant] startDraggingCell:cell fromTabBarControl:self withMouseDownEvent:[self lastMouseDownEvent]];
		}
	}
}

- (void)mouseUp:(NSEvent *)theEvent {
	if(_resizing) {
		_resizing = NO;
		[[NSCursor arrowCursor] set];
	} else {
		// what cell?
		NSPoint mousePt = [self convertPoint:[theEvent locationInWindow] fromView:nil];
		NSRect cellFrame, mouseDownCellFrame;
		PSMTabBarCell *cell = [self cellForPoint:mousePt cellFrame:&cellFrame];
		PSMTabBarCell *mouseDownCell = [self cellForPoint:[self convertPoint:[[self lastMouseDownEvent] locationInWindow] fromView:nil] cellFrame:&mouseDownCellFrame];
		if(cell) {
			NSPoint trackingStartPoint = [self convertPoint:[[self lastMouseDownEvent] locationInWindow] fromView:nil];
			NSRect iconRect = [mouseDownCell closeButtonRectForBounds:mouseDownCellFrame];

			if((NSMouseInRect(mousePt, iconRect, [self isFlipped])) && ![self disableTabClose] && ![cell isCloseButtonSuppressed] && [mouseDownCell closeButtonPressed]) {
				if(([[NSApp currentEvent] modifierFlags] & NSAlternateKeyMask) != 0) {
					//If the user is holding Option, close all other tabs
                    NSArray *tmpCellArray = [[self cells] copy];
                    for (PSMTabBarCell *otherCell in tmpCellArray) {
						if(otherCell != cell) {
							[self performSelector:@selector(closeTabClick:) withObject:otherCell];
						}
					}
                    
                    [tmpCellArray release], tmpCellArray = nil;
                    
					//Fix the close button for the clicked tab not to be pressed
					[cell setCloseButtonPressed:NO];
				} else {
					//Otherwise, close this tab
					[self performSelector:@selector(closeTabClick:) withObject:cell];
				}
			} else if(NSMouseInRect(mousePt, mouseDownCellFrame, [self isFlipped]) &&
					  (!NSMouseInRect(trackingStartPoint, [cell closeButtonRectForBounds:cellFrame], [self isFlipped]) || ![self allowsBackgroundTabClosing] || [self disableTabClose])) {
				[mouseDownCell setCloseButtonPressed:NO];
				// If -[self selectsTabsOnMouseDown] is TRUE, we already performed tabClick: on mouseDown.
				if(![self selectsTabsOnMouseDown]) {
					[self performSelector:@selector(tabClick:) withObject:cell];
				}
			} else {
				[mouseDownCell setCloseButtonPressed:NO];
				[self performSelector:@selector(tabNothing:) withObject:cell];
			}
		}

		_closeClicked = NO;
	}
}

- (NSMenu *)menuForEvent:(NSEvent *)event {
	NSMenu *menu = nil;
	NSTabViewItem *item = [[self cellForPoint:[self convertPoint:[event locationInWindow] fromView:nil] cellFrame:nil] representedObject];

	if(item && [[self delegate] respondsToSelector:@selector(tabView:menuForTabViewItem:)]) {
		menu = [[self delegate] tabView:tabView menuForTabViewItem:item];
	}
	return menu;
}

#pragma mark -
#pragma mark Drag and Drop

- (BOOL)shouldDelayWindowOrderingForEvent:(NSEvent *)theEvent {
	return YES;
}

// NSDraggingSource
- (NSDragOperation)draggingSourceOperationMaskForLocal:(BOOL)isLocal {
	return(isLocal ? NSDragOperationMove : NSDragOperationNone);
}

- (BOOL)ignoreModifierKeysWhileDragging {
	return YES;
}

- (void)draggedImage:(NSImage *)anImage beganAt:(NSPoint)screenPoint {
	[[PSMTabDragAssistant sharedDragAssistant] draggingBeganAt:screenPoint];
}

- (void)draggedImage:(NSImage *)image movedTo:(NSPoint)screenPoint {
	[[PSMTabDragAssistant sharedDragAssistant] draggingMovedTo:screenPoint];
}

// NSDraggingDestination
- (NSDragOperation)draggingEntered:(id <NSDraggingInfo>)sender {
	if([[[sender draggingPasteboard] types] indexOfObject:@"PSMTabBarControlItemPBType"] != NSNotFound) {
		if([self delegate] && [[self delegate] respondsToSelector:@selector(tabView:shouldDropTabViewItem:inTabBar:)] &&
		   ![[self delegate] tabView:[[sender draggingSource] tabView] shouldDropTabViewItem:[[[PSMTabDragAssistant sharedDragAssistant] draggedCell] representedObject] inTabBar:self]) {
			return NSDragOperationNone;
		}

		[[PSMTabDragAssistant sharedDragAssistant] draggingEnteredTabBarControl:self atPoint:[self convertPoint:[sender draggingLocation] fromView:nil]];
		return NSDragOperationMove;
	}

	return NSDragOperationNone;
}

- (NSDragOperation)draggingUpdated:(id <NSDraggingInfo>)sender {
	PSMTabBarCell *cell = [self cellForPoint:[self convertPoint:[sender draggingLocation] fromView:nil] cellFrame:nil];

	if([[[sender draggingPasteboard] types] indexOfObject:@"PSMTabBarControlItemPBType"] != NSNotFound) {
		if([self delegate] && [[self delegate] respondsToSelector:@selector(tabView:shouldDropTabViewItem:inTabBar:)] &&
		   ![[self delegate] tabView:[[sender draggingSource] tabView] shouldDropTabViewItem:[[[PSMTabDragAssistant sharedDragAssistant] draggedCell] representedObject] inTabBar:self]) {
			return NSDragOperationNone;
		}

		[[PSMTabDragAssistant sharedDragAssistant] draggingUpdatedInTabBarControl:self atPoint:[self convertPoint:[sender draggingLocation] fromView:nil]];
		return NSDragOperationMove;
	} else if(cell) {
		//something that was accepted by the delegate was dragged on

		//Test for the space bar (the skip-the-delay key).
		/*enum { virtualKeycodeForSpace = 49 }; //Source: IM:Tx (Fig. C-2)
		   union {
		        KeyMap keymap;
		        char bits[16];
		   } keymap;
		   GetKeys(keymap.keymap);
		   if ((GetCurrentEventKeyModifiers() == 0) && bit_test(keymap.bits, virtualKeycodeForSpace)) {
		        //The user pressed the space bar. This skips the delay; the user wants to pop the spring on this tab *now*.

		        //For some reason, it crashes if I call -fire here. I don't know why. It doesn't crash if I simply set the fire date to now.
		        [_springTimer setFireDate:[NSDate date]];
		   } else {*/
		//Wind the spring for a spring-loaded drop.
		//The delay time comes from Finder's defaults, which specifies it in milliseconds.
		//If the delegate can't handle our spring-loaded drop, we'll abort it when the timer fires. See fireSpring:. This is simpler than constantly (checking for spring-loaded awareness and tearing down/rebuilding the timer) at every delegate change.

		//If the user has dragged to a different tab, reset the timer.
		if(_tabViewItemWithSpring != [cell representedObject]) {
			[_springTimer invalidate];
			[_springTimer release]; _springTimer = nil;
			_tabViewItemWithSpring = [cell representedObject];
		}
		if(!_springTimer) {
			//Finder's default delay time, as of Tiger, is 668 ms. If the user has never changed it, there's no setting in its defaults, so we default to that amount.
			NSNumber *delayNumber = [(NSNumber *)CFPreferencesCopyAppValue((CFStringRef)@"SpringingDelayMilliseconds", (CFStringRef)@"com.apple.finder") autorelease];
			NSTimeInterval delaySeconds = delayNumber ?[delayNumber doubleValue] / 1000.0 : 0.668;
			_springTimer = [[NSTimer scheduledTimerWithTimeInterval:delaySeconds
							 target:self
							 selector:@selector(fireSpring:)
							 userInfo:sender
							 repeats:NO] retain];
		}
		return NSDragOperationCopy;
	}

	return NSDragOperationNone;
}

- (void)draggingExited:(id <NSDraggingInfo>)sender {
	[_springTimer invalidate];
	[_springTimer release]; _springTimer = nil;

	[[PSMTabDragAssistant sharedDragAssistant] draggingExitedTabBarControl:self];
}

- (BOOL)prepareForDragOperation:(id <NSDraggingInfo>)sender {
	//validate the drag operation only if there's a valid tab bar to drop into
	return [[[sender draggingPasteboard] types] indexOfObject:@"PSMTabBarControlItemPBType"] == NSNotFound ||
		   [[PSMTabDragAssistant sharedDragAssistant] destinationTabBar] != nil;
}

- (BOOL)performDragOperation:(id <NSDraggingInfo>)sender {
	if([[[sender draggingPasteboard] types] indexOfObject:@"PSMTabBarControlItemPBType"] != NSNotFound) {
		[[PSMTabDragAssistant sharedDragAssistant] performDragOperation];
	} else if([self delegate] && [[self delegate] respondsToSelector:@selector(tabView:acceptedDraggingInfo:onTabViewItem:)]) {
		//forward the drop to the delegate
		[[self delegate] tabView:tabView acceptedDraggingInfo:sender onTabViewItem:[[self cellForPoint:[self convertPoint:[sender draggingLocation] fromView:nil] cellFrame:nil] representedObject]];
	}
	return YES;
}

- (void)draggedImage:(NSImage *)anImage endedAt:(NSPoint)aPoint operation:(NSDragOperation)operation {
	[[PSMTabDragAssistant sharedDragAssistant] draggedImageEndedAt:aPoint operation:operation];
}

- (void)concludeDragOperation:(id <NSDraggingInfo>)sender {
}

#pragma mark -
#pragma mark Spring-loading

- (void)fireSpring:(NSTimer *)timer {
	NSAssert1(timer == _springTimer, @"Spring fired by unrecognized timer %@", timer);

	id <NSDraggingInfo> sender = [timer userInfo];
	PSMTabBarCell *cell = [self cellForPoint:[self convertPoint:[sender draggingLocation] fromView:nil] cellFrame:nil];
	[tabView selectTabViewItem:[cell representedObject]];

	_tabViewItemWithSpring = nil;
	[_springTimer invalidate];
	[_springTimer release]; _springTimer = nil;
}

#pragma mark -
#pragma mark Actions

- (void)overflowMenuAction:(id)sender {
	NSTabViewItem *tabViewItem = (NSTabViewItem *)[sender representedObject];
	[tabView selectTabViewItem:tabViewItem];
}

- (void)closeTabClick:(id)sender {

    if (([_cells count] == 1) && (![self canCloseOnlyTab])) {
		return;
	}

	[sender retain];

    if (([self delegate]) && ([[self delegate] respondsToSelector:@selector(tabView:shouldCloseTabViewItem:)])) {
        if (![[self delegate] tabView:tabView shouldCloseTabViewItem:[sender representedObject]]) {
             // fix mouse downed close button
             [sender setCloseButtonPressed:NO];
             return;
         }
    }

    if (([self delegate]) && ([[self delegate] respondsToSelector:@selector(tabView:willCloseTabViewItem:)])) {
         [[self delegate] tabView:tabView willCloseTabViewItem:[sender representedObject]];
    }
     
    [[sender representedObject] retain];
    [tabView removeTabViewItem:[sender representedObject]];
     
    if (([self delegate]) && ([[self delegate] respondsToSelector:@selector(tabView:didCloseTabViewItem:)])) {
         [[self delegate] tabView:tabView didCloseTabViewItem:[sender representedObject]];
    }
    [[sender representedObject] release];

	[sender release];
}

- (void)tabClick:(id)sender {
	[tabView selectTabViewItem:[sender representedObject]];
}

- (void)tabNothing:(id)sender {
	//[self update];  // takes care of highlighting based on state
}

- (void)frameDidChange:(NSNotification *)notification {
	[self _checkWindowFrame];

	// trying to address the drawing artifacts for the progress indicators - hackery follows
	// this one fixes the "blanking" effect when the control hides and shows itself
    for (PSMTabBarCell *cell in _cells) {
		[[cell indicator] stopAnimation:self];

		[[cell indicator] performSelector:@selector(startAnimation:)
		 withObject:nil
		 afterDelay:0];
	}

	[self update:NO];
}

- (void)viewDidMoveToWindow {
	[self _checkWindowFrame];
}

- (void)viewWillStartLiveResize {
    for (PSMTabBarCell *cell in _cells) {
		[[cell indicator] stopAnimation:self];
	}
	[self setNeedsDisplay:YES];
}

-(void)viewDidEndLiveResize {
    for (PSMTabBarCell *cell in _cells) {
		[[cell indicator] startAnimation:self];
	}

	[self _checkWindowFrame];
	[self update:NO];
}

- (void)resetCursorRects {
	[super resetCursorRects];
	if([self orientation] == PSMTabBarVerticalOrientation) {
		NSRect frame = [self frame];
		[self addCursorRect:NSMakeRect(frame.size.width - 2, 0, 2, frame.size.height) cursor:[NSCursor resizeLeftRightCursor]];
	}
}

- (void)windowDidMove:(NSNotification *)aNotification {
	[self setNeedsDisplay:YES];
}

- (void)windowDidUpdate:(NSNotification *)notification {
	// hide? must readjust things if I'm not supposed to be showing
	// this block of code only runs when the app launches
	if([self hideForSingleTab] && ([_cells count] <= 1) && !_awakenedFromNib) {
		// must adjust frames now before display
		NSRect myFrame = [self frame];
		if([self orientation] == PSMTabBarHorizontalOrientation) {
			if(partnerView) {
				NSRect partnerFrame = [partnerView frame];
				// above or below me?
				if(myFrame.origin.y - 22 > [partnerView frame].origin.y) {
					// partner is below me
					[self setFrame:NSMakeRect(myFrame.origin.x, myFrame.origin.y + 21, myFrame.size.width, myFrame.size.height - 21)];
					[partnerView setFrame:NSMakeRect(partnerFrame.origin.x, partnerFrame.origin.y, partnerFrame.size.width, partnerFrame.size.height + 21)];
				} else {
					// partner is above me
					[self setFrame:NSMakeRect(myFrame.origin.x, myFrame.origin.y, myFrame.size.width, myFrame.size.height - 21)];
					[partnerView setFrame:NSMakeRect(partnerFrame.origin.x, partnerFrame.origin.y - 21, partnerFrame.size.width, partnerFrame.size.height + 21)];
				}
				[partnerView setNeedsDisplay:YES];
				[self setNeedsDisplay:YES];
			} else {
				// for window movement
				NSRect windowFrame = [[self window] frame];
				[[self window] setFrame:NSMakeRect(windowFrame.origin.x, windowFrame.origin.y + 21, windowFrame.size.width, windowFrame.size.height - 21) display:YES];
				[self setFrame:NSMakeRect(myFrame.origin.x, myFrame.origin.y, myFrame.size.width, myFrame.size.height - 21)];
			}
		} else {
			if(partnerView) {
				NSRect partnerFrame = [partnerView frame];
				//to the left or right?
				if(myFrame.origin.x < [partnerView frame].origin.x) {
					// partner is to the left
					[self setFrame:NSMakeRect(myFrame.origin.x, myFrame.origin.y, 1, myFrame.size.height)];
					[partnerView setFrame:NSMakeRect(partnerFrame.origin.x - myFrame.size.width + 1, partnerFrame.origin.y, partnerFrame.size.width + myFrame.size.width - 1, partnerFrame.size.height)];
				} else {
					// partner to the right
					[self setFrame:NSMakeRect(myFrame.origin.x + myFrame.size.width, myFrame.origin.y, 1, myFrame.size.height)];
					[partnerView setFrame:NSMakeRect(partnerFrame.origin.x, partnerFrame.origin.y, partnerFrame.size.width + myFrame.size.width, partnerFrame.size.height)];
				}
				_tabBarWidth = myFrame.size.width;
				[partnerView setNeedsDisplay:YES];
				[self setNeedsDisplay:YES];
			} else {
				// for window movement
				NSRect windowFrame = [[self window] frame];
				[[self window] setFrame:NSMakeRect(windowFrame.origin.x + myFrame.size.width - 1, windowFrame.origin.y, windowFrame.size.width - myFrame.size.width + 1, windowFrame.size.height) display:YES];
				[self setFrame:NSMakeRect(myFrame.origin.x, myFrame.origin.y, 1, myFrame.size.height)];
			}
		}

		_isHidden = YES;

		if([[self delegate] respondsToSelector:@selector(tabView:tabBarDidHide:)]) {
			[[self delegate] tabView:[self tabView] tabBarDidHide:self];
		}
	}

	_awakenedFromNib = YES;
	[self setNeedsDisplay:YES];
}

#pragma mark -
#pragma mark Menu Validation

- (BOOL)validateMenuItem:(NSMenuItem *)sender {
	[sender setState:([[sender representedObject] isEqualTo:[tabView selectedTabViewItem]]) ? NSOnState : NSOffState];

	return [[self delegate] respondsToSelector:@selector(tabView:validateOverflowMenuItem:forTabViewItem:)] ?
		   [[self delegate] tabView:[self tabView] validateOverflowMenuItem:sender forTabViewItem:[sender representedObject]] : YES;
}

#pragma mark -
#pragma mark NSTabView Delegate

- (void)tabView:(NSTabView *)aTabView didSelectTabViewItem:(NSTabViewItem *)tabViewItem {
	// here's a weird one - this message is sent before the "tabViewDidChangeNumberOfTabViewItems"
	// message, thus I can end up updating when there are no cells, if no tabs were (yet) present
	NSInteger tabIndex = [aTabView indexOfTabViewItem:tabViewItem];

	if([_cells count] > 0 && tabIndex < [_cells count]) {
		PSMTabBarCell *thisCell = [_cells objectAtIndex:tabIndex];
		if(_alwaysShowActiveTab && [thisCell isInOverflowMenu]) {
			//temporarily disable the delegate in order to move the tab to a different index
			id tempDelegate = [aTabView delegate];
			[aTabView setDelegate:nil];

			// move it all around first
			[tabViewItem retain];
			[thisCell retain];
			[aTabView removeTabViewItem:tabViewItem];
			[aTabView insertTabViewItem:tabViewItem atIndex:0];
            [self removeCellAtIndex:tabIndex];
            [self insertCell:thisCell atIndex:0];
			[thisCell setIsInOverflowMenu:NO];                  //very important else we get a fun recursive loop going
			[[_cells objectAtIndex:[_cells count] - 1] setIsInOverflowMenu:YES];             //these 2 lines are pretty uncool and this logic needs to be updated
			[thisCell release];
			[tabViewItem release];

			[aTabView setDelegate:tempDelegate];

			//reset the selection since removing it changed the selection
			[aTabView selectTabViewItem:tabViewItem];

			[self update];
		} else {
			[_controller setSelectedCell:thisCell];
			[self setNeedsDisplay:YES];
		}
	}

	if([[self delegate] respondsToSelector:@selector(tabView:didSelectTabViewItem:)]) {
		[[self delegate] performSelector:@selector(tabView:didSelectTabViewItem:) withObject:aTabView withObject:tabViewItem];
	}
}

- (BOOL)tabView:(NSTabView *)aTabView shouldSelectTabViewItem:(NSTabViewItem *)tabViewItem {
	if([[self delegate] respondsToSelector:@selector(tabView:shouldSelectTabViewItem:)]) {
		return [[self delegate] tabView:aTabView shouldSelectTabViewItem:tabViewItem];
	} else {
		return YES;
	}
}
- (void)tabView:(NSTabView *)aTabView willSelectTabViewItem:(NSTabViewItem *)tabViewItem {
	if([[self delegate] respondsToSelector:@selector(tabView:willSelectTabViewItem:)]) {
		[[self delegate] performSelector:@selector(tabView:willSelectTabViewItem:) withObject:aTabView withObject:tabViewItem];
	}
}

- (void)tabViewDidChangeNumberOfTabViewItems:(NSTabView *)aTabView {
	NSArray *tabItems = [tabView tabViewItems];
	// go through cells, remove any whose representedObjects are not in [tabView tabViewItems]
    NSArray *tmpCellArray = [_cells copy];
    for (PSMTabBarCell *cell in tmpCellArray) {
		//remove the observer binding
		if([cell representedObject] && ![tabItems containsObject:[cell representedObject]]) {
			if ([[self delegate] respondsToSelector:@selector(tabView:didDetachTabViewItem:)]) {
				[[self delegate] tabView:aTabView didDetachTabViewItem:[cell representedObject]];
			}

			[self removeTabForCell:cell];
		}
	}
    [tmpCellArray release], tmpCellArray = nil;

	// go through tab view items, add cell for any not present
	NSMutableArray *cellItems = [self representedTabViewItems];  
    NSUInteger i = 0;
    for (NSTabViewItem *item in tabItems) {
		if(![cellItems containsObject:item]) {
			[self addTabViewItem:item atIndex:i];
		}
    ++i;
	}

	// pass along for other delegate responses
	if([[self delegate] respondsToSelector:@selector(tabViewDidChangeNumberOfTabViewItems:)]) {
		[[self delegate] performSelector:@selector(tabViewDidChangeNumberOfTabViewItems:) withObject:aTabView];
	}

	// reset cursor tracking for the add tab button if one exists
	if([self addTabButton]) {
		[[self addTabButton] resetCursorRects];
	}
}

#pragma mark -
#pragma mark Tooltips

- (NSString *)view:(NSView *)view stringForToolTip:(NSToolTipTag)tag point:(NSPoint)point userData:(void *)userData {
	if([[self delegate] respondsToSelector:@selector(tabView:toolTipForTabViewItem:)]) {
		return [[self delegate] tabView:[self tabView] toolTipForTabViewItem:[[self cellForPoint:point cellFrame:nil] representedObject]];
	}
	return nil;
}

#pragma mark -
#pragma mark Archiving

- (void)encodeWithCoder:(NSCoder *)aCoder 
{
	[super encodeWithCoder:aCoder];
	if ([aCoder allowsKeyedCoding]) {
		[aCoder encodeObject:_cells forKey:@"PSMcells"];
		[aCoder encodeObject:tabView forKey:@"PSMtabView"];
		[aCoder encodeObject:_overflowPopUpButton forKey:@"PSMoverflowPopUpButton"];
		[aCoder encodeObject:_addTabButton forKey:@"PSMaddTabButton"];
		[aCoder encodeObject:style forKey:@"PSMstyle"];
		[aCoder encodeInteger:_orientation forKey:@"PSMorientation"];
		[aCoder encodeBool:_canCloseOnlyTab forKey:@"PSMcanCloseOnlyTab"];
		[aCoder encodeBool:_disableTabClose forKey:@"PSMdisableTabClose"];
		[aCoder encodeBool:_hideForSingleTab forKey:@"PSMhideForSingleTab"];
		[aCoder encodeBool:_allowsBackgroundTabClosing forKey:@"PSMallowsBackgroundTabClosing"];
		[aCoder encodeBool:_allowsResizing forKey:@"PSMallowsResizing"];
		[aCoder encodeBool:_selectsTabsOnMouseDown forKey:@"PSMselectsTabsOnMouseDown"];
		[aCoder encodeBool:_showAddTabButton forKey:@"PSMshowAddTabButton"];
		[aCoder encodeBool:_sizeCellsToFit forKey:@"PSMsizeCellsToFit"];
		[aCoder encodeInteger:_cellMinWidth forKey:@"PSMcellMinWidth"];
		[aCoder encodeInteger:_cellMaxWidth forKey:@"PSMcellMaxWidth"];
		[aCoder encodeInteger:_cellOptimumWidth forKey:@"PSMcellOptimumWidth"];
		[aCoder encodeInteger:_currentStep forKey:@"PSMcurrentStep"];
		[aCoder encodeBool:_isHidden forKey:@"PSMisHidden"];
		[aCoder encodeObject:partnerView forKey:@"PSMpartnerView"];
		[aCoder encodeBool:_awakenedFromNib forKey:@"PSMawakenedFromNib"];
		[aCoder encodeObject:_lastMouseDownEvent forKey:@"PSMlastMouseDownEvent"];
		[aCoder encodeObject:delegate forKey:@"PSMdelegate"];
		[aCoder encodeBool:_useOverflowMenu forKey:@"PSMuseOverflowMenu"];
		[aCoder encodeBool:_automaticallyAnimates forKey:@"PSMautomaticallyAnimates"];
		[aCoder encodeBool:_alwaysShowActiveTab forKey:@"PSMalwaysShowActiveTab"];
	}
}

- (id)initWithCoder:(NSCoder *)aDecoder 
{
	self = [super initWithCoder:aDecoder];
	if (self) {
		// Initialization
		[self initAddedProperties];
		[self registerForDraggedTypes:[NSArray arrayWithObjects:@"PSMTabBarControlItemPBType", nil]];
		
		// resize
		[self setPostsFrameChangedNotifications:YES];
		[[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(frameDidChange:) name:NSViewFrameDidChangeNotification object:self];
		if ([aDecoder allowsKeyedCoding]) {
			_cells = [[aDecoder decodeObjectForKey:@"PSMcells"] retain];
			tabView = [[aDecoder decodeObjectForKey:@"PSMtabView"] retain];
			_overflowPopUpButton = [[aDecoder decodeObjectForKey:@"PSMoverflowPopUpButton"] retain];
			_addTabButton = [[aDecoder decodeObjectForKey:@"PSMaddTabButton"] retain];
			style = [[aDecoder decodeObjectForKey:@"PSMstyle"] retain];
			_orientation = (PSMTabBarOrientation)[aDecoder decodeIntegerForKey:@"PSMorientation"];
			_canCloseOnlyTab = [aDecoder decodeBoolForKey:@"PSMcanCloseOnlyTab"];
			_disableTabClose = [aDecoder decodeBoolForKey:@"PSMdisableTabClose"];
			_hideForSingleTab = [aDecoder decodeBoolForKey:@"PSMhideForSingleTab"];
			_allowsBackgroundTabClosing = [aDecoder decodeBoolForKey:@"PSMallowsBackgroundTabClosing"];
			_allowsResizing = [aDecoder decodeBoolForKey:@"PSMallowsResizing"];
			_selectsTabsOnMouseDown = [aDecoder decodeBoolForKey:@"PSMselectsTabsOnMouseDown"];
			_showAddTabButton = [aDecoder decodeBoolForKey:@"PSMshowAddTabButton"];
			_sizeCellsToFit = [aDecoder decodeBoolForKey:@"PSMsizeCellsToFit"];
			_cellMinWidth = [aDecoder decodeIntegerForKey:@"PSMcellMinWidth"];
			_cellMaxWidth = [aDecoder decodeIntegerForKey:@"PSMcellMaxWidth"];
			_cellOptimumWidth = [aDecoder decodeIntegerForKey:@"PSMcellOptimumWidth"];
			_currentStep = [aDecoder decodeIntegerForKey:@"PSMcurrentStep"];
			_isHidden = [aDecoder decodeBoolForKey:@"PSMisHidden"];
			partnerView = [[aDecoder decodeObjectForKey:@"PSMpartnerView"] retain];
			_awakenedFromNib = [aDecoder decodeBoolForKey:@"PSMawakenedFromNib"];
			_lastMouseDownEvent = [[aDecoder decodeObjectForKey:@"PSMlastMouseDownEvent"] retain];
			_useOverflowMenu = [aDecoder decodeBoolForKey:@"PSMuseOverflowMenu"];
			_automaticallyAnimates = [aDecoder decodeBoolForKey:@"PSMautomaticallyAnimates"];
			_alwaysShowActiveTab = [aDecoder decodeBoolForKey:@"PSMalwaysShowActiveTab"];
			delegate = [[aDecoder decodeObjectForKey:@"PSMdelegate"] retain];
		}
	}
//	[self setTarget:self];
	return self;
}

#pragma mark -
#pragma mark Convenience

- (void)bindPropertiesForCell:(PSMTabBarCell *)cell andTabViewItem:(NSTabViewItem *)item {
	[self _bindPropertiesForCell:cell andTabViewItem:item];

	// watch for changes in the identifier
	[item addObserver:self forKeyPath:@"identifier" options:NSKeyValueObservingOptionOld context:nil];
}

- (void)_bindPropertiesForCell:(PSMTabBarCell *)cell andTabViewItem:(NSTabViewItem *)item {
	// bind the indicator to the represented object's status (if it exists)
	[[cell indicator] setHidden:YES];
	if([item identifier] != nil) {
		if([[[cell representedObject] identifier] respondsToSelector:@selector(isProcessing)]) {
			NSMutableDictionary *bindingOptions = [NSMutableDictionary dictionary];
			[bindingOptions setObject:NSNegateBooleanTransformerName forKey:@"NSValueTransformerName"];
			[[cell indicator] bind:@"animate" toObject:[item identifier] withKeyPath:@"isProcessing" options:nil];
			[[cell indicator] bind:@"hidden" toObject:[item identifier] withKeyPath:@"isProcessing" options:bindingOptions];
			[[item identifier] addObserver:cell forKeyPath:@"isProcessing" options:0 context:nil];
		}
	}

	// bind for the existence of an icon
	[cell setHasIcon:NO];
	if([item identifier] != nil) {
		if([[[cell representedObject] identifier] respondsToSelector:@selector(icon)]) {
			NSMutableDictionary *bindingOptions = [NSMutableDictionary dictionary];
			[bindingOptions setObject:NSIsNotNilTransformerName forKey:@"NSValueTransformerName"];
			[cell bind:@"hasIcon" toObject:[item identifier] withKeyPath:@"icon" options:bindingOptions];
			[[item identifier] addObserver:cell forKeyPath:@"icon" options:0 context:nil];
		}
	}

	// bind for the existence of a counter
	[cell setCount:0];
	if([item identifier] != nil) {
		if([[[cell representedObject] identifier] respondsToSelector:@selector(objectCount)]) {
			[cell bind:@"count" toObject:[item identifier] withKeyPath:@"objectCount" options:nil];
			[[item identifier] addObserver:cell forKeyPath:@"objectCount" options:0 context:nil];
		}
	}

	// bind for the color of a counter
	[cell setCountColor:nil];
	if([item identifier] != nil) {
		if([[[cell representedObject] identifier] respondsToSelector:@selector(countColor)]) {
			[cell bind:@"countColor" toObject:[item identifier] withKeyPath:@"countColor" options:nil];
			[[item identifier] addObserver:cell forKeyPath:@"countColor" options:0 context:nil];
		}
	}

	// bind for a large image
	[cell setHasLargeImage:NO];
	if([item identifier] != nil) {
		if([[[cell representedObject] identifier] respondsToSelector:@selector(largeImage)]) {
			NSMutableDictionary *bindingOptions = [NSMutableDictionary dictionary];
			[bindingOptions setObject:NSIsNotNilTransformerName forKey:@"NSValueTransformerName"];
			[cell bind:@"hasLargeImage" toObject:[item identifier] withKeyPath:@"largeImage" options:bindingOptions];
			[[item identifier] addObserver:cell forKeyPath:@"largeImage" options:0 context:nil];
		}
	}

	[cell setIsEdited:NO];
	if([item identifier] != nil) {
		if([[[cell representedObject] identifier] respondsToSelector:@selector(isEdited)]) {
			[cell bind:@"isEdited" toObject:[item identifier] withKeyPath:@"isEdited" options:nil];
			[[item identifier] addObserver:cell forKeyPath:@"isEdited" options:0 context:nil];
		}
	}

	// bind my string value to the label on the represented tab
	[cell bind:@"title" toObject:item withKeyPath:@"label" options:nil];
}

- (NSMutableArray *)representedTabViewItems {
	NSMutableArray *temp = [NSMutableArray arrayWithCapacity:[_cells count]];
    for (PSMTabBarCell *cell in _cells) {
		if([cell representedObject]) {
			[temp addObject:[cell representedObject]];
		}
	}
	return temp;
}

- (id)cellForPoint:(NSPoint)point cellFrame:(NSRectPointer)outFrame {
	if([self orientation] == PSMTabBarHorizontalOrientation && !NSPointInRect(point, [self genericCellRect])) {
		return nil;
	}

	NSInteger i, cnt = [_cells count];
	for(i = 0; i < cnt; i++) {
		PSMTabBarCell *cell = [_cells objectAtIndex:i];

		if(NSPointInRect(point, [cell frame])) {
			if(outFrame) {
				*outFrame = [cell frame];
			}
			return cell;
		}
	}
	return nil;
}

- (PSMTabBarCell *)lastVisibleTab {
	NSInteger i, cellCount = [_cells count];
	for(i = 0; i < cellCount; i++) {
		if([[_cells objectAtIndex:i] isInOverflowMenu]) {
            if (i == 0)
                return nil;
            else
                return [_cells objectAtIndex:(i - 1)];
		}
	}
    if (cellCount > 0)
        return [_cells objectAtIndex:(cellCount - 1)];
    else
        return nil;
}

- (NSInteger)numberOfVisibleTabs {
	NSInteger i, cellCount = 0;
	PSMTabBarCell *nextCell;

	for(i = 0; i < [_cells count]; i++) {
		nextCell = [_cells objectAtIndex:i];

		if([nextCell isInOverflowMenu]) {
			break;
		}

		if(![nextCell isPlaceholder]) {
			cellCount++;
		}
	}

	return cellCount;
}

#pragma mark -
#pragma mark Accessibility

-(BOOL)accessibilityIsIgnored {
	return NO;
}

- (id)accessibilityAttributeValue:(NSString *)attribute {
	id attributeValue = nil;
	if([attribute isEqualToString: NSAccessibilityRoleAttribute]) {
		attributeValue = NSAccessibilityGroupRole;
	} else if([attribute isEqualToString: NSAccessibilityChildrenAttribute]) {
		attributeValue = NSAccessibilityUnignoredChildren(_cells);
	} else {
		attributeValue = [super accessibilityAttributeValue:attribute];
	}
	return attributeValue;
}

- (id)accessibilityHitTest:(NSPoint)point {
	id hitTestResult = self;

	NSEnumerator *enumerator = [_cells objectEnumerator];
	PSMTabBarCell *cell = nil;
	PSMTabBarCell *highlightedCell = nil;

	while(!highlightedCell && (cell = [enumerator nextObject])) {
		if([cell isHighlighted]) {
			highlightedCell = cell;
		}
	}

	if(highlightedCell) {
		hitTestResult = [highlightedCell accessibilityHitTest:point];
	}

	return hitTestResult;
}

#pragma mark -
#pragma mark Private Methods

- (CGFloat)_heightOfTabCells {
    return kPSMTabBarControlHeight;
}

- (CGFloat)_rightMargin {
    return MARGIN_X;
}

- (CGFloat)_leftMargin {
    return MARGIN_X;
}

- (CGFloat)_topMargin {
    return MARGIN_Y;
}

- (CGFloat)_bottomMargin {
    return MARGIN_Y;
}

- (NSSize)_addTabButtonSize {

    if ([self orientation] == PSMTabBarHorizontalOrientation)
        return NSMakeSize(12.0,[self frame].size.height);
    else
        return NSMakeSize([self frame].size.width,18.0);
}

- (NSRect)_addTabButtonRect {
    
    if ([[self addTabButton] isHidden])
        return NSZeroRect;

    NSRect theRect;
    NSSize buttonSize = [self _addTabButtonSize];
    
    if ([self orientation] == PSMTabBarHorizontalOrientation) {
        
        CGFloat xOffset = kPSMTabBarCellPadding;
        PSMTabBarCell *lastVisibleTab = [self lastVisibleTab];
        if (lastVisibleTab)
            xOffset += NSMaxX([lastVisibleTab frame]);
        
        theRect = NSMakeRect(xOffset, NSMinY([self bounds]), buttonSize.width, buttonSize.height);
    } else {        
        CGFloat yOffset = 0;
        PSMTabBarCell *lastVisibleTab = [self lastVisibleTab];
        if (lastVisibleTab)
            yOffset += NSMaxY([lastVisibleTab frame]);
        
        theRect = NSMakeRect(NSMinX([self bounds]), yOffset, buttonSize.width, buttonSize.height);
    }
            
    return theRect;
}

- (NSSize)_overflowButtonSize {

    if ([self orientation] == PSMTabBarHorizontalOrientation)
        return NSMakeSize(14.0,[self frame].size.height);
    else
        return NSMakeSize([self frame].size.width,18.0);
}

- (NSRect)_overflowButtonRect {

    if ([[self overflowPopUpButton] isHidden])
        return NSZeroRect;

    NSRect theRect;
    NSSize buttonSize = [self _overflowButtonSize];
    
    if ([self orientation] == PSMTabBarHorizontalOrientation) {
        
        theRect = NSMakeRect(NSMaxX([self bounds]) - [self rightMargin] - buttonSize.width -kPSMTabBarCellPadding, 0.0, buttonSize.width, buttonSize.height);
    } else {
        
        theRect = NSMakeRect(NSMinX([self bounds]), NSMaxY([self bounds]) - [self bottomMargin] - buttonSize.height, buttonSize.width, buttonSize.height);
    }

    return theRect;
}

- (void)_drawTabBarControlInRect:(NSRect)aRect {

    [self drawBezelInRect:aRect];
    [self drawInteriorInRect:aRect];
}

- (void)_drawBezelInRect:(NSRect)rect {
    // default implementation draws nothing
}

- (void)_drawInteriorInRect:(NSRect)rect {

	// no tab view == not connected
	if(![self tabView]) {
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
    for (PSMTabBarCell *cell in [self cells]) {
		if([self isAnimating] || (![cell isInOverflowMenu] && NSIntersectsRect([cell frame], rect))) {
			[cell drawWithFrame:[cell frame] inTabBarControl:self];
		}
	}
}

@end
