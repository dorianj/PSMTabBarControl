//
//  PSMTabDragAssistant.m
//  PSMTabBarControl
//
//  Created by John Pannell on 4/10/06.
//  Copyright 2006 Positive Spin Media. All rights reserved.
//

#import "PSMTabDragAssistant.h"
#import "PSMTabBarCell.h"
#import "PSMTabStyle.h"
#import "PSMTabDragWindowController.h"

@interface PSMTabBarControl (SharedPrivate)
- (void)update:(BOOL)animate;
- (id)cellForPoint:(NSPoint) point cellFrame:(NSRectPointer)outFrame;
@end

@interface PSMTabDragAssistant (Private)
- (NSImage *)_imageForViewOfCell:(PSMTabBarCell *)cell styleMask:(NSUInteger *)outMask;
- (NSImage *)_miniwindowImageOfWindow:(NSWindow *)window;
- (void)_expandWindow:(NSWindow *)window atPoint:(NSPoint)point;
@end

@implementation PSMTabDragAssistant

static PSMTabDragAssistant *sharedDragAssistant = nil;

#pragma mark -
#pragma mark Creation/Destruction

+ (PSMTabDragAssistant *)sharedDragAssistant {
	if(!sharedDragAssistant) {
		sharedDragAssistant = [[PSMTabDragAssistant alloc] init];
	}

	return sharedDragAssistant;
}

- (id)init {
	if((self = [super init])) {
		_sourceTabBar = nil;
		_destinationTabBar = nil;
		_participatingTabBars = [[NSMutableSet alloc] init];
		_draggedCell = nil;
		_animationTimer = nil;
		_sineCurveWidths = [[NSMutableArray alloc] initWithCapacity:kPSMTabDragAnimationSteps];
		_targetCell = nil;
		_isDragging = NO;
	}

	return self;
}

- (void)dealloc {
	[_sourceTabBar release];
	[_destinationTabBar release];
	[_participatingTabBars release];
	[_draggedCell release];
	[_animationTimer release];
	[_sineCurveWidths release];
	[_targetCell release];
	[super dealloc];
}

#pragma mark -
#pragma mark Accessors

- (PSMTabBarControl *)sourceTabBar {
	return _sourceTabBar;
}

- (void)setSourceTabBar:(PSMTabBarControl *)tabBar {
	[tabBar retain];
	[_sourceTabBar release];
	_sourceTabBar = tabBar;
}

- (PSMTabBarControl *)destinationTabBar {
	return _destinationTabBar;
}

- (void)setDestinationTabBar:(PSMTabBarControl *)tabBar {
	[tabBar retain];
	[_destinationTabBar release];
	_destinationTabBar = tabBar;
}

- (PSMTabBarCell *)draggedCell {
	return _draggedCell;
}

- (void)setDraggedCell:(PSMTabBarCell *)cell {
	[cell retain];
	[_draggedCell release];
	_draggedCell = cell;
}

- (NSInteger)draggedCellIndex {
	return _draggedCellIndex;
}

- (void)setDraggedCellIndex:(NSInteger)value {
	_draggedCellIndex = value;
}

- (BOOL)isDragging {
	return _isDragging;
}

- (void)setIsDragging:(BOOL)value {
	_isDragging = value;
}

- (NSPoint)currentMouseLoc {
	return _currentMouseLoc;
}

- (void)setCurrentMouseLoc:(NSPoint)point {
	_currentMouseLoc = point;
}

- (PSMTabBarCell *)targetCell {
	return _targetCell;
}

- (void)setTargetCell:(PSMTabBarCell *)cell {
	[cell retain];
	[_targetCell release];
	_targetCell = cell;
}

#pragma mark -
#pragma mark Functionality

- (void)startDraggingCell:(PSMTabBarCell *)cell fromTabBarControl:(PSMTabBarControl *)tabBarControl withMouseDownEvent:(NSEvent *)event {
	[self setIsDragging:YES];
	[self setSourceTabBar:tabBarControl];
	[self setDestinationTabBar:tabBarControl];
	[_participatingTabBars addObject:tabBarControl];
	[self setDraggedCell:cell];
	[self setDraggedCellIndex:[[tabBarControl cells] indexOfObject:cell]];

	NSRect cellFrame = [cell frame];
	// list of widths for animation
	NSInteger i;
	CGFloat cellStepSize = ([tabBarControl orientation] == PSMTabBarHorizontalOrientation) ? (cellFrame.size.width + 6) : (cellFrame.size.height + 1);
	for(i = 0; i < kPSMTabDragAnimationSteps - 1; i++) {
		NSInteger thisWidth = (NSInteger)(cellStepSize - ((cellStepSize / 2.0) + ((sin((M_PI / 2.0) + ((CGFloat)i / (CGFloat)kPSMTabDragAnimationSteps) * M_PI) * cellStepSize) / 2.0)));
		[_sineCurveWidths addObject:[NSNumber numberWithInteger:thisWidth]];
	}
	[_sineCurveWidths addObject:[NSNumber numberWithInteger:([tabBarControl orientation] == PSMTabBarHorizontalOrientation) ? cellFrame.size.width : cellFrame.size.height]];

	// hide UI buttons
	[[tabBarControl overflowPopUpButton] setHidden:YES];
	[[tabBarControl addTabButton] setHidden:YES];

	[[NSCursor closedHandCursor] set];

	NSPasteboard *pboard = [NSPasteboard pasteboardWithName:NSDragPboard];
	NSImage *dragImage = [cell dragImage];
	[[cell indicator] removeFromSuperview];
	[self distributePlaceholdersInTabBarControl:tabBarControl withDraggedCell:cell];

	if([tabBarControl isFlipped]) {
		cellFrame.origin.y += cellFrame.size.height;
	}

	//clear all highlights
	[[tabBarControl cells] enumerateObjectsUsingBlock:^(id cell, NSUInteger idx, BOOL *stop) {
		[cell setHighlighted:NO];
	}];

	NSSize offset = NSZeroSize;
	[pboard declareTypes:[NSArray arrayWithObjects:@"PSMTabBarControlItemPBType", nil] owner: nil];
	[pboard setString:[[NSNumber numberWithInteger:[[tabBarControl cells] indexOfObject:cell]] stringValue] forType:@"PSMTabBarControlItemPBType"];
	_animationTimer = [NSTimer scheduledTimerWithTimeInterval:(1.0 / 30.0) target:self selector:@selector(animateDrag:) userInfo:nil repeats:YES];

	[[NSNotificationCenter defaultCenter] postNotificationName:PSMTabDragDidBeginNotification object:nil];

	//retain the control in case the drag operation causes the control to be released
	[tabBarControl retain];

	if([tabBarControl delegate] && [[tabBarControl delegate] respondsToSelector:@selector(tabView:shouldDropTabViewItem:inTabBar:)] &&
	   [[tabBarControl delegate] tabView:[tabBarControl tabView] shouldDropTabViewItem:[[self draggedCell] representedObject] inTabBar:nil]) {
		_currentTearOffStyle = [tabBarControl tearOffStyle];
		_draggedTab = [[PSMTabDragWindowController alloc] initWithImage:dragImage styleMask:NSBorderlessWindowMask tearOffStyle:_currentTearOffStyle];

		cellFrame.origin.y -= cellFrame.size.height;
		[tabBarControl dragImage:[[[NSImage alloc] initWithSize:NSMakeSize(1, 1)] autorelease] at:cellFrame.origin offset:offset event:event pasteboard:pboard source:tabBarControl slideBack:NO];
	} else {
		[tabBarControl dragImage:dragImage at:cellFrame.origin offset:offset event:event pasteboard:pboard source:tabBarControl slideBack:YES];
	}

	[tabBarControl release];
}

- (void)draggingEnteredTabBarControl:(PSMTabBarControl *)tabBarControl atPoint:(NSPoint)mouseLoc {
    //don't use the source tab bar if the dragged tab is the only tab in it, this leads to lost tabs
    if (tabBarControl == _sourceTabBar && tabBarControl.numberOfVisibleTabs == 0)
        return;

	if(_currentTearOffStyle == PSMTabBarTearOffMiniwindow && ![self destinationTabBar]) {
		[_draggedTab switchImages];
	}

	[self setDestinationTabBar:tabBarControl];
	[self setCurrentMouseLoc:mouseLoc];
	// hide UI buttons
	[[tabBarControl overflowPopUpButton] setHidden:YES];
	[[tabBarControl addTabButton] setHidden:YES];
	if([[tabBarControl cells] count] == 0 || ![[[tabBarControl cells] objectAtIndex:0] isPlaceholder]) {
		[self distributePlaceholdersInTabBarControl:tabBarControl];
	}
	[_participatingTabBars addObject:tabBarControl];

	//tell the drag window to display only the header if there is one
	if(_currentTearOffStyle == PSMTabBarTearOffAlphaWindow && _draggedView) {
		if(_fadeTimer) {
			[_fadeTimer invalidate];
		}

		[[_draggedTab window] orderFront:nil];
		_fadeTimer = [NSTimer scheduledTimerWithTimeInterval:1.0 / 30.0 target:self selector:@selector(fadeOutDragWindow:) userInfo:nil repeats:YES];
	}
}

- (void)draggingUpdatedInTabBarControl:(PSMTabBarControl *)tabBarControl atPoint:(NSPoint)mouseLoc {
    //don't use the source tab bar if the dragged tab is the only tab in it, this leads to lost tabs
    if (tabBarControl == _sourceTabBar && tabBarControl.numberOfVisibleTabs == 0)
        return;

	if([self destinationTabBar] != tabBarControl) {
		[self setDestinationTabBar:tabBarControl];
	}
	[self setCurrentMouseLoc:mouseLoc];
}

- (void)draggingExitedTabBarControl:(PSMTabBarControl *)tabBarControl {
	if([[tabBarControl delegate] respondsToSelector:@selector(tabView:shouldAllowTabViewItem:toLeaveTabBar:)] &&
	   ![[tabBarControl delegate] tabView:[tabBarControl tabView] shouldAllowTabViewItem:[[self draggedCell] representedObject] toLeaveTabBar:tabBarControl]) {
		return;
	}

	[self setDestinationTabBar:nil];
	[self setCurrentMouseLoc:NSMakePoint(-1.0, -1.0)];

	if(_fadeTimer) {
		[_fadeTimer invalidate];
		_fadeTimer = [NSTimer scheduledTimerWithTimeInterval:1.0 / 30.0 target:self selector:@selector(fadeInDragWindow:) userInfo:nil repeats:YES];
	} else if(_draggedTab) {
		if(_currentTearOffStyle == PSMTabBarTearOffAlphaWindow) {
			//create a new floating drag window
			if(!_draggedView) {
				NSUInteger styleMask;
				NSImage *viewImage = [self _imageForViewOfCell:[self draggedCell] styleMask:&styleMask];

				_draggedView = [[PSMTabDragWindowController alloc] initWithImage:viewImage styleMask:styleMask tearOffStyle:PSMTabBarTearOffAlphaWindow];
				[[_draggedView window] setAlphaValue:0.0];
			}

            NSPoint windowOrigin = [[_draggedTab window] frame].origin;
            
			windowOrigin.x -= _dragWindowOffset.width;
			windowOrigin.y += _dragWindowOffset.height;
            
			[[_draggedView window] setFrameTopLeftPoint:windowOrigin];
			[[_draggedView window] orderWindow:NSWindowBelow relativeTo:[[_draggedTab window] windowNumber]];
		} else if(_currentTearOffStyle == PSMTabBarTearOffMiniwindow && ![_draggedTab alternateImage]) {
			NSImage *image;
			NSSize imageSize;
			NSUInteger mask;             //we don't need this but we can't pass nil in for the style mask, as some delegate implementations will crash

			if(!(image = [self _miniwindowImageOfWindow:[tabBarControl window]])) {
				image = [self _imageForViewOfCell:[self draggedCell] styleMask:&mask];
			}

			imageSize = [image size];
			[image setScalesWhenResized:YES];

			if(imageSize.width > imageSize.height) {
				[image setSize:NSMakeSize(125, 125 * (imageSize.height / imageSize.width))];
			} else {
				[image setSize:NSMakeSize(125 * (imageSize.width / imageSize.height), 125)];
			}

			[_draggedTab setAlternateImage:image];
		}

		//set the window's alpha mask to zero if the last tab is being dragged
		//don't fade out the old window if the delegate doesn't respond to the new tab bar method, just to be safe
		if([[[self sourceTabBar] tabView] numberOfTabViewItems] == 1 && [self sourceTabBar] == tabBarControl &&
		   [[[self sourceTabBar] delegate] respondsToSelector:@selector(tabView:newTabBarForDraggedTabViewItem:atPoint:)]) {
			[[[self sourceTabBar] window] setAlphaValue:0.0];

			if([_sourceTabBar tearOffStyle] == PSMTabBarTearOffAlphaWindow) {
				[[_draggedView window] setAlphaValue:kPSMTabDragWindowAlpha];
			} else {
				//#warning fix me - what should we do when the last tab is dragged as a miniwindow?
			}
		} else {
			if([_sourceTabBar tearOffStyle] == PSMTabBarTearOffAlphaWindow) {
				_fadeTimer = [NSTimer scheduledTimerWithTimeInterval:1.0 / 30.0 target:self selector:@selector(fadeInDragWindow:) userInfo:nil repeats:YES];
			} else {
				[_draggedTab switchImages];
				_centersDragWindows = YES;
			}
		}
	}
}

- (void)performDragOperation {
	// move cell
	NSInteger destinationIndex = [[[self destinationTabBar] cells] indexOfObject:[self targetCell]];

	//there is the slight possibility of the targetCell now being set properly, so avoid errors
	if(destinationIndex >= [[[self destinationTabBar] cells] count]) {
		destinationIndex = [[[self destinationTabBar] cells] count] - 1;
	}

	[[self destinationTabBar] replaceCellAtIndex:destinationIndex withCell:[self draggedCell]];
	[[self draggedCell] setControlView:[self destinationTabBar]];

	// move actual NSTabViewItem
	if([self sourceTabBar] != [self destinationTabBar]) {
		//remove bindings registered on the old tab
		[[self sourceTabBar] removeTabForCell:[self draggedCell]];

		NSInteger i, insertIndex;
		NSArray *cells = [[self destinationTabBar] cells];

		//find the index of where the dragged cell was just dropped
		for(i = 0, insertIndex = 0; (i < [cells count]) && ([cells objectAtIndex:i] != [self draggedCell]); i++, insertIndex++) {
			if([[cells objectAtIndex:i] isPlaceholder]) {
				insertIndex--;
			}
		}

		[[[self sourceTabBar] tabView] removeTabViewItem:[[self draggedCell] representedObject]];
		[[[self destinationTabBar] tabView] insertTabViewItem:[[self draggedCell] representedObject] atIndex:insertIndex];

		//calculate the position for the dragged cell
		if([[self destinationTabBar] automaticallyAnimates]) {
			if(insertIndex > 0) {
				NSRect cellRect = [[cells objectAtIndex:insertIndex - 1] frame];
				cellRect.origin.x += cellRect.size.width;
				[[self draggedCell] setFrame:cellRect];
			}
		}

		//rebind the cell to the new control
		[[self destinationTabBar] bindPropertiesForCell:[self draggedCell] andTabViewItem:[[self draggedCell] representedObject]];

		//select the newly moved item in the destination tab view
		[[[self destinationTabBar] tabView] selectTabViewItem:[[self draggedCell] representedObject]];
	} else {
		//have to do this before checking the index of a cell otherwise placeholders will be counted
		[self removeAllPlaceholdersFromTabBarControl:[self sourceTabBar]];

		//rearrange the tab view items
		NSTabView *tabView = [[self sourceTabBar] tabView];
		NSTabViewItem *item = [[self draggedCell] representedObject];
		BOOL reselect = ([tabView selectedTabViewItem] == item);
		NSInteger index;
		NSArray *cells = [[self sourceTabBar] cells];

		//find the index of where the dragged cell was just dropped
		for(index = 0; index < [cells count] && [cells objectAtIndex:index] != [self draggedCell]; index++) {
			;
		}

		//temporarily disable the delegate in order to move the tab to a different index
		id tempDelegate = [tabView delegate];
		[tabView setDelegate:nil];
		[item retain];
		[tabView removeTabViewItem:item];
		[tabView insertTabViewItem:item atIndex:index];
        [item release];
		if(reselect) {
			[tabView selectTabViewItem:item];
		}
		[tabView setDelegate:tempDelegate];
	}

	if(([self sourceTabBar] != [self destinationTabBar] || [[[self sourceTabBar] cells] indexOfObject:[self draggedCell]] != _draggedCellIndex) && [[[self sourceTabBar] delegate] respondsToSelector:@selector(tabView:didDropTabViewItem:inTabBar:)]) {
		[[[self sourceTabBar] delegate] tabView:[[self sourceTabBar] tabView] didDropTabViewItem:[[self draggedCell] representedObject] inTabBar:[self destinationTabBar]];
	}

	[[NSNotificationCenter defaultCenter] postNotificationName:PSMTabDragDidEndNotification object:nil];

	[self finishDrag];
}

- (void)draggedImageEndedAt:(NSPoint)aPoint operation:(NSDragOperation)operation {
	if([self isDragging]) {   // means there was not a successful drop (performDragOperation)
		id sourceDelegate = [[self sourceTabBar] delegate];

		//split off the dragged tab into a new window
		if([self destinationTabBar] == nil &&
		   sourceDelegate && [sourceDelegate respondsToSelector:@selector(tabView:shouldDropTabViewItem:inTabBar:)] &&
		   [sourceDelegate tabView:[[self sourceTabBar] tabView] shouldDropTabViewItem:[[self draggedCell] representedObject] inTabBar:nil] &&
		   [sourceDelegate respondsToSelector:@selector(tabView:newTabBarForDraggedTabViewItem:atPoint:)]) {
			PSMTabBarControl *control = [sourceDelegate tabView:[[self sourceTabBar] tabView] newTabBarForDraggedTabViewItem:[[self draggedCell] representedObject] atPoint:aPoint];

			if(control) {
				//add the dragged tab to the new window
				[control insertCell:[self draggedCell] atIndex:0];

				//remove bindings registered on the old tab
				[[self sourceTabBar] removeTabForCell:[self draggedCell]];

				//rebind the cell to the new control
				[control bindPropertiesForCell:[self draggedCell] andTabViewItem:[[self draggedCell] representedObject]];

				[[self draggedCell] setControlView:control];

				[[[self sourceTabBar] tabView] removeTabViewItem:[[self draggedCell] representedObject]];

				[[control tabView] addTabViewItem:[[self draggedCell] representedObject]];
				[control update:NO];                 //make sure the new tab is set in the correct position

				if(_currentTearOffStyle == PSMTabBarTearOffAlphaWindow) {
					[[control window] makeKeyAndOrderFront:nil];
				} else {
					//center the window over where we ended dragging
					[self _expandWindow:[control window] atPoint:[NSEvent mouseLocation]];
				}

				if([sourceDelegate respondsToSelector:@selector(tabView:didDropTabViewItem:inTabBar:)]) {
					[sourceDelegate tabView:[[self sourceTabBar] tabView] didDropTabViewItem:[[self draggedCell] representedObject] inTabBar:control];
				}
			} else {
				NSLog(@"Delegate returned no control to add to.");
				[[self sourceTabBar] insertCell:[self draggedCell] atIndex:[self draggedCellIndex]];
			}
		} else {
			// put cell back
			[[self sourceTabBar] insertCell:[self draggedCell] atIndex:[self draggedCellIndex]];
		}

		[[NSNotificationCenter defaultCenter] postNotificationName:PSMTabDragDidEndNotification object:nil];

		[self finishDrag];
	}
}

- (void)finishDrag {
	if([[[self sourceTabBar] tabView] numberOfTabViewItems] == 0 && [[[self sourceTabBar] delegate] respondsToSelector:@selector(tabView:closeWindowForLastTabViewItem:)]) {
		[[[self sourceTabBar] delegate] tabView:[[self sourceTabBar] tabView] closeWindowForLastTabViewItem:[[self draggedCell] representedObject]];
	}

	if(_draggedTab) {
		[[_draggedTab window] orderOut:nil];
		[_draggedTab release];
		_draggedTab = nil;
	}

	if(_draggedView) {
		[[_draggedView window] orderOut:nil];
		[_draggedView release];
		_draggedView = nil;
	}

	_centersDragWindows = NO;

	[self setIsDragging:NO];
	[self removeAllPlaceholdersFromTabBarControl:[self sourceTabBar]];
	[self setSourceTabBar:nil];
	[self setDestinationTabBar:nil];

    for (PSMTabBarControl *tabBar in _participatingTabBars) {
		[self removeAllPlaceholdersFromTabBarControl:tabBar];
	}
	[_participatingTabBars removeAllObjects];
	[self setDraggedCell:nil];
	[_animationTimer invalidate];
	_animationTimer = nil;
	[_sineCurveWidths removeAllObjects];
	[self setTargetCell:nil];
}

- (void)draggingBeganAt:(NSPoint)aPoint {
	if(_draggedTab) {
		[[_draggedTab window] setFrameTopLeftPoint:aPoint];
		[[_draggedTab window] orderFront:nil];

		if([[[self sourceTabBar] tabView] numberOfTabViewItems] == 1) {
			[self draggingExitedTabBarControl:[self sourceTabBar]];
		}
	}
}

- (void)draggingMovedTo:(NSPoint)aPoint {
	if(_draggedTab) {
		if(_centersDragWindows) {
			if([_draggedTab isAnimating]) {
				return;
			}

			//Ignore aPoint, as it seems to give wacky values
			NSRect frame = [[_draggedTab window] frame];
			frame.origin = [NSEvent mouseLocation];
			frame.origin.x -= frame.size.width / 2;
			frame.origin.y -= frame.size.height / 2;
			[[_draggedTab window] setFrame:frame display:NO];
		} else {
			[[_draggedTab window] setFrameTopLeftPoint:aPoint];
		}

		if(_draggedView) {
			//move the view representation with the tab
			//the relative position of the dragged view window will be different
			//depending on the position of the tab bar relative to the controlled tab view

			aPoint.y -= [[_draggedTab window] frame].size.height;
			aPoint.x -= _dragWindowOffset.width;
			aPoint.y += _dragWindowOffset.height;
			[[_draggedView window] setFrameTopLeftPoint:aPoint];
		}
	}
}

- (void)fadeInDragWindow:(NSTimer *)timer {
	CGFloat value = [[_draggedView window] alphaValue];
	if(value >= kPSMTabDragWindowAlpha || _draggedTab == nil) {
		[timer invalidate];
		_fadeTimer = nil;
	} else {
		[[_draggedTab window] setAlphaValue:[[_draggedTab window] alphaValue] - kPSMTabDragAlphaInterval];
		[[_draggedView window] setAlphaValue:value + kPSMTabDragAlphaInterval];
	}
}

- (void)fadeOutDragWindow:(NSTimer *)timer {
	CGFloat value = [[_draggedView window] alphaValue];
	NSWindow *tabWindow = [_draggedTab window], *viewWindow = [_draggedView window];

	if(value <= 0.0) {
		[viewWindow setAlphaValue:0.0];
		[tabWindow setAlphaValue:kPSMTabDragWindowAlpha];

		[timer invalidate];
		_fadeTimer = nil;
	} else {
		if([tabWindow alphaValue] < kPSMTabDragWindowAlpha) {
			[tabWindow setAlphaValue:[tabWindow alphaValue] + kPSMTabDragAlphaInterval];
		}
		[viewWindow setAlphaValue:value - kPSMTabDragAlphaInterval];
	}
}

#pragma mark -
#pragma mark Private

- (NSImage *)_imageForViewOfCell:(PSMTabBarCell *)cell styleMask:(NSUInteger *)outMask {
	PSMTabBarControl *control = [cell controlView];
	NSImage *viewImage = nil;

	if(outMask) {
		*outMask = NSBorderlessWindowMask;
	}

	if([control delegate] && [[control delegate] respondsToSelector:@selector(tabView:imageForTabViewItem:offset:styleMask:)]) {
		//get a custom image representation of the view to drag from the delegate
		NSImage *tabImage = [_draggedTab image];
		NSPoint drawPoint;
		_dragWindowOffset = NSZeroSize;
		viewImage = [[control delegate] tabView:[control tabView] imageForTabViewItem:[cell representedObject] offset:&_dragWindowOffset styleMask:outMask];
		[viewImage lockFocus];

		//draw the tab into the returned window, that way we don't have two windows being dragged (this assumes the tab will be on the window)
		drawPoint = NSMakePoint(_dragWindowOffset.width, [viewImage size].height - _dragWindowOffset.height);

		if([control orientation] == PSMTabBarHorizontalOrientation) {
			drawPoint.y += [control heightOfTabCells] - [tabImage size].height;
			_dragWindowOffset.height -= [control heightOfTabCells] - [tabImage size].height;
		} else {
			drawPoint.x += [control frame].size.width - [tabImage size].width;
		}

        [tabImage drawAtPoint:drawPoint fromRect:NSZeroRect operation:NSCompositeSourceOver fraction:1.0];

		[viewImage unlockFocus];
	} else {
		//the delegate doesn't give a custom image, so use an image of the view
		NSView *tabView = [[cell representedObject] view];
		viewImage = [[[NSImage alloc] initWithSize:[tabView frame].size] autorelease];
		[viewImage lockFocus];
		[tabView drawRect:[tabView bounds]];
		[viewImage unlockFocus];
	}

	if(outMask && (*outMask | NSBorderlessWindowMask)) {
		_dragWindowOffset.height += 22;
	}

	return viewImage;
}

- (NSImage *)_miniwindowImageOfWindow:(NSWindow *)window {
	NSRect rect = [window frame];
	NSImage *image = [[[NSImage alloc] initWithSize:rect.size] autorelease];
	[image lockFocus];
	rect.origin = NSZeroPoint;
	CGContextCopyWindowCaptureContentsToRect([[NSGraphicsContext currentContext] graphicsPort], *(CGRect *)&rect, [NSApp contextID], [window windowNumber], 0);
	[image unlockFocus];

	return image;
}

- (void)_expandWindow:(NSWindow *)window atPoint:(NSPoint)point {
	NSRect frame = [window frame];
	[window setFrameTopLeftPoint:NSMakePoint(point.x - frame.size.width / 2, point.y + frame.size.height / 2)];
	[window setAlphaValue:0.0];
	[window makeKeyAndOrderFront:nil];

	NSAnimation *animation = [[NSAnimation alloc] initWithDuration:0.25 animationCurve:NSAnimationEaseInOut];
	[animation setAnimationBlockingMode:NSAnimationNonblocking];
	[animation setCurrentProgress:0.1];
	[animation startAnimation];
	NSTimer *timer = [NSTimer scheduledTimerWithTimeInterval:1.0 / 30.0 target:self selector:@selector(_expandWindowTimerFired:) userInfo:[NSDictionary dictionaryWithObjectsAndKeys:window, @"Window", animation, @"Animation", nil] repeats:YES];
    [animation release];
    
	[[NSRunLoop currentRunLoop] addTimer:timer forMode:NSEventTrackingRunLoopMode];
}

- (void)_expandWindowTimerFired:(NSTimer *)timer {
	NSWindow *window = [[timer userInfo] objectForKey:@"Window"];
	NSAnimation *animation = [[timer userInfo] objectForKey:@"Animation"];
	CGAffineTransform transform;
	NSPoint translation;
	NSRect winFrame = [window frame];

	translation.x = (winFrame.size.width / 2.0);
	translation.y = (winFrame.size.height / 2.0);
	transform = CGAffineTransformMakeTranslation(translation.x, translation.y);
	transform = CGAffineTransformScale(transform, 1.0 / [animation currentValue], 1.0 / [animation currentValue]);
	transform = CGAffineTransformTranslate(transform, -translation.x, -translation.y);

	translation.x = -winFrame.origin.x;
	translation.y = winFrame.origin.y + winFrame.size.height - [[NSScreen mainScreen] frame].size.height;

	transform = CGAffineTransformTranslate(transform, translation.x, translation.y);

	CGSSetWindowTransform([NSApp contextID], [window windowNumber], transform);

	[window setAlphaValue:[animation currentValue]];

	if(![animation isAnimating]) {
		[timer invalidate];
	}
}

#pragma mark -
#pragma mark Animation

- (void)animateDrag:(NSTimer *)timer {

    NSSet *tabBarControls = [[_participatingTabBars copy] autorelease];
    for (PSMTabBarControl *tabBarControl in tabBarControls) {
		[self calculateDragAnimationForTabBarControl:tabBarControl];
		[[NSRunLoop currentRunLoop] performSelector:@selector(display) target:tabBarControl argument:nil order:1 modes:[NSArray arrayWithObjects:@"NSEventTrackingRunLoopMode", @"NSDefaultRunLoopMode", nil]];
	}
}

- (void)calculateDragAnimationForTabBarControl:(PSMTabBarControl *)tabBarControl {
	BOOL removeFlag = YES;
	NSArray *cells = [tabBarControl cells];
	NSInteger i, cellCount = [cells count];
	CGFloat position = [tabBarControl orientation] == PSMTabBarHorizontalOrientation ?[[tabBarControl style] leftMarginForTabBarControl:tabBarControl] :[[tabBarControl style] topMarginForTabBarControl:tabBarControl];

	// identify target cell
	// mouse at beginning of tabs
	NSPoint mouseLoc = [self currentMouseLoc];
	if([self destinationTabBar] == tabBarControl) {
		removeFlag = NO;
		if(mouseLoc.x < [[tabBarControl style] leftMarginForTabBarControl:tabBarControl]) {
			[self setTargetCell:[cells objectAtIndex:0]];
		} else {
			NSRect overCellRect;
			PSMTabBarCell *overCell = [tabBarControl cellForPoint:mouseLoc cellFrame:&overCellRect];
			if(overCell) {
				// mouse among cells - placeholder
				if([overCell isPlaceholder]) {
					[self setTargetCell:overCell];
				} else if([tabBarControl orientation] == PSMTabBarHorizontalOrientation) {
					// non-placeholders - horizontal orientation
					if(mouseLoc.x < (overCellRect.origin.x + (overCellRect.size.width / 2.0))) {
						// mouse on left side of cell
						[self setTargetCell:[cells objectAtIndex:([cells indexOfObject:overCell] - 1)]];
					} else {
						// mouse on right side of cell
						[self setTargetCell:[cells objectAtIndex:([cells indexOfObject:overCell] + 1)]];
					}
				} else {
					// non-placeholders - vertical orientation
					if(mouseLoc.y < (overCellRect.origin.y + (overCellRect.size.height / 2.0))) {
						// mouse on top of cell
						[self setTargetCell:[cells objectAtIndex:([cells indexOfObject:overCell] - 1)]];
					} else {
						// mouse on bottom of cell
						[self setTargetCell:[cells objectAtIndex:([cells indexOfObject:overCell] + 1)]];
					}
				}
			} else {
				// out at end - must find proper cell (could be more in overflow menu)
				[self setTargetCell:[tabBarControl lastVisibleTab]];
			}
		}
	} else {
		[self setTargetCell:nil];
	}

	for(i = 0; i < cellCount; i++) {
		PSMTabBarCell *cell = [cells objectAtIndex:i];
		NSRect newRect = [cell frame];
		if(![cell isInOverflowMenu]) {
			if([cell isPlaceholder]) {
				if(cell == [self targetCell]) {
					[cell setCurrentStep:([cell currentStep] + 1)];
				} else {
					[cell setCurrentStep:([cell currentStep] - 1)];
					if([cell currentStep] > 0) {
						removeFlag = NO;
					}
				}

				if([tabBarControl orientation] == PSMTabBarHorizontalOrientation) {
					newRect.size.width = [[_sineCurveWidths objectAtIndex:[cell currentStep]] integerValue];
				} else {
					newRect.size.height = [[_sineCurveWidths objectAtIndex:[cell currentStep]] integerValue];
				}
			}
		} else {
			break;
		}

		if([tabBarControl orientation] == PSMTabBarHorizontalOrientation) {
			newRect.origin.x = position;
			position += newRect.size.width;
		} else {
			newRect.origin.y = position;
			position += newRect.size.height;
		}
		[cell setFrame:newRect];
		if([cell indicator]) {
			[[cell indicator] setFrame:[cell indicatorRectForBounds:newRect]];
		}
	}
	if(removeFlag) {
		[_participatingTabBars removeObject:tabBarControl];
		[self removeAllPlaceholdersFromTabBarControl:tabBarControl];
	}
}

#pragma mark -
#pragma mark Placeholders

- (void)distributePlaceholdersInTabBarControl:(PSMTabBarControl *)tabBarControl withDraggedCell:(PSMTabBarCell *)cell {
	// called upon first drag - must distribute placeholders
	[self distributePlaceholdersInTabBarControl:tabBarControl];

	NSArray *cells = [tabBarControl cells];

	// replace dragged cell with a placeholder, and clean up surrounding cells
	NSInteger cellIndex = [cells indexOfObject:cell];
	PSMTabBarCell *pc = [[[PSMTabBarCell alloc] initPlaceholderWithFrame:[[self draggedCell] frame] expanded:YES inTabBarControl:tabBarControl] autorelease];
    [pc setControlView:tabBarControl];
	[tabBarControl replaceCellAtIndex:cellIndex withCell:pc];
	[tabBarControl removeCellAtIndex:(cellIndex + 1)];
	[tabBarControl removeCellAtIndex:(cellIndex - 1)];

	if(cellIndex - 2 >= 0) {
		pc = [cells objectAtIndex:cellIndex - 2];
		[pc setTabState:~[pc tabState] & PSMTab_RightIsSelectedMask];
	}
}

- (void)distributePlaceholdersInTabBarControl:(PSMTabBarControl *)tabBarControl {
	NSInteger i, numVisibleTabs = [tabBarControl numberOfVisibleTabs];
	for(i = 0; i < numVisibleTabs; i++) {
		PSMTabBarCell *pc = [[[PSMTabBarCell alloc] initPlaceholderWithFrame:[[self draggedCell] frame] expanded:NO inTabBarControl:tabBarControl] autorelease];
        [pc setControlView:tabBarControl];
		[tabBarControl insertCell:pc atIndex:(2 * i)];
	}

	PSMTabBarCell *pc = [[[PSMTabBarCell alloc] initPlaceholderWithFrame:[[self draggedCell] frame] expanded:NO inTabBarControl:tabBarControl] autorelease];
    [pc setControlView:tabBarControl];
	if([[tabBarControl cells] count] > (2 * numVisibleTabs)) {
		[tabBarControl insertCell:pc atIndex:(2 * numVisibleTabs)];
	} else {
		[tabBarControl addCell:pc];
	}
}

- (void)removeAllPlaceholdersFromTabBarControl:(PSMTabBarControl *)tabBarControl {
	NSInteger i, cellCount = [[tabBarControl cells] count];
	for(i = (cellCount - 1); i >= 0; i--) {
		PSMTabBarCell *cell = [[tabBarControl cells] objectAtIndex:i];
		if([cell isPlaceholder]) {
			[tabBarControl removeTabForCell:cell];
		}
	}
	// redraw
	[tabBarControl update:NO];
}

#pragma mark -
#pragma mark Archiving

- (void)encodeWithCoder:(NSCoder *)aCoder {
	//[super encodeWithCoder:aCoder];
	if([aCoder allowsKeyedCoding]) {
		[aCoder encodeObject:_sourceTabBar forKey:@"sourceTabBar"];
		[aCoder encodeObject:_destinationTabBar forKey:@"destinationTabBar"];
		[aCoder encodeObject:_participatingTabBars forKey:@"participatingTabBars"];
		[aCoder encodeObject:_draggedCell forKey:@"draggedCell"];
		[aCoder encodeInteger:_draggedCellIndex forKey:@"draggedCellIndex"];
		[aCoder encodeBool:_isDragging forKey:@"isDragging"];
		[aCoder encodeObject:_animationTimer forKey:@"animationTimer"];
		[aCoder encodeObject:_sineCurveWidths forKey:@"sineCurveWidths"];
		[aCoder encodePoint:_currentMouseLoc forKey:@"currentMouseLoc"];
		[aCoder encodeObject:_targetCell forKey:@"targetCell"];
	}
}

- (id)initWithCoder:(NSCoder *)aDecoder {
	//self = [super initWithCoder:aDecoder];
	//if (self) {
	if([aDecoder allowsKeyedCoding]) {
		_sourceTabBar = [[aDecoder decodeObjectForKey:@"sourceTabBar"] retain];
		_destinationTabBar = [[aDecoder decodeObjectForKey:@"destinationTabBar"] retain];
		_participatingTabBars = [[aDecoder decodeObjectForKey:@"participatingTabBars"] retain];
		_draggedCell = [[aDecoder decodeObjectForKey:@"draggedCell"] retain];
		_draggedCellIndex = [aDecoder decodeIntegerForKey:@"draggedCellIndex"];
		_isDragging = [aDecoder decodeBoolForKey:@"isDragging"];
		_animationTimer = [[aDecoder decodeObjectForKey:@"animationTimer"] retain];
		_sineCurveWidths = [[aDecoder decodeObjectForKey:@"sineCurveWidths"] retain];
		_currentMouseLoc = [aDecoder decodePointForKey:@"currentMouseLoc"];
		_targetCell = [[aDecoder decodeObjectForKey:@"targetCell"] retain];
	}
	//}
	return self;
}


@end
