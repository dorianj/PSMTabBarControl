//
//  PSMCardTabStyle.m
//  PSMTabBarControl
//
//  Created by Michael Monscheuer on 9/3/12.
//
//

#import "PSMCardTabStyle.h"

@interface PSMTabBarControl(SharedPrivates)

- (void)_drawInteriorInRect:(NSRect)rect;
- (NSRect)_addTabButtonRect;

@end

@implementation PSMCardTabStyle

@synthesize leftMarginForTabBarControl = _leftMargin;

+ (NSString *)name {
    return @"Card";
}

- (NSString *)name {
	return [[self class] name];
}

#pragma mark -
#pragma mark Creation/Destruction

- (id) init {
    if ( (self = [super init]) ) {
        cardCloseButton = [[NSImage alloc] initByReferencingFile:[[PSMTabBarControl bundle] pathForImageResource:@"AquaTabClose_Front"]];
        cardCloseButtonDown = [[NSImage alloc] initByReferencingFile:[[PSMTabBarControl bundle] pathForImageResource:@"AquaTabClose_Front_Pressed"]];
        cardCloseButtonOver = [[NSImage alloc] initByReferencingFile:[[PSMTabBarControl bundle] pathForImageResource:@"AquaTabClose_Front_Rollover"]];
        
        cardCloseDirtyButton = [[NSImage alloc] initByReferencingFile:[[PSMTabBarControl bundle] pathForImageResource:@"AquaTabCloseDirty_Front"]];
        cardCloseDirtyButtonDown = [[NSImage alloc] initByReferencingFile:[[PSMTabBarControl bundle] pathForImageResource:@"AquaTabCloseDirty_Front_Pressed"]];
        cardCloseDirtyButtonOver = [[NSImage alloc] initByReferencingFile:[[PSMTabBarControl bundle] pathForImageResource:@"AquaTabCloseDirty_Front_Rollover"]];
        
        _addTabButtonImage = [[NSImage alloc] initByReferencingFile:[[PSMTabBarControl bundle] pathForImageResource:@"AquaTabNew"]];
        _addTabButtonPressedImage = [[NSImage alloc] initByReferencingFile:[[PSMTabBarControl bundle] pathForImageResource:@"AquaTabNewPressed"]];
        _addTabButtonRolloverImage = [[NSImage alloc] initByReferencingFile:[[PSMTabBarControl bundle] pathForImageResource:@"AquaTabNewRollover"]];
                
		_leftMargin = 5.0;
	}
    return self;
}

- (void)dealloc {
    [cardCloseButton release];
    [cardCloseButtonDown release];
    [cardCloseButtonOver release];
    [cardCloseDirtyButton release];
    [cardCloseDirtyButtonDown release];
    [cardCloseDirtyButtonOver release]; 
    [_addTabButtonImage release];
    [_addTabButtonPressedImage release];
    [_addTabButtonRolloverImage release];
        
    [super dealloc];
}

#pragma mark -
#pragma mark Control Specific

- (CGFloat)leftMarginForTabBarControl:(PSMTabBarControl *)tabBarControl {
	return _leftMargin;
}

- (CGFloat)rightMarginForTabBarControl:(PSMTabBarControl *)tabBarControl {
    return _leftMargin;
}

- (CGFloat)topMarginForTabBarControl:(PSMTabBarControl *)tabBarControl {
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

- (NSRect)dragRectForTabCell:(PSMTabBarCell *)cell ofTabBarControl:(PSMTabBarControl *)tabBarControl {
	NSRect dragRect = [cell frame];
	dragRect.size.width++;
	return dragRect;
}

#pragma mark -
#pragma mark Providing Images

- (NSImage *)closeButtonImageOfType:(PSMCloseButtonImageType)type forTabCell:(PSMTabBarCell *)cell
{
    switch (type) {
        case PSMCloseButtonImageTypeStandard:
            return cardCloseButton;
        case PSMCloseButtonImageTypeRollover:
            return cardCloseButtonOver;
        case PSMCloseButtonImageTypePressed:
            return cardCloseButtonDown;
            
        case PSMCloseButtonImageTypeDirty:
            return cardCloseDirtyButton;
        case PSMCloseButtonImageTypeDirtyRollover:
            return cardCloseDirtyButtonOver;
        case PSMCloseButtonImageTypeDirtyPressed:
            return cardCloseDirtyButtonDown;
            
        default:
            break;
    }
}

#pragma mark -
#pragma mark Drawing

- (void)drawBezelOfTabBarControl:(PSMTabBarControl *)tabBarControl inRect:(NSRect)rect {
	//Draw for our whole bounds; it'll be automatically clipped to fit the appropriate drawing area
	NSRect bounds = [tabBarControl bounds];
    
    bounds.size.height -= 1.0;    

    NSGradient *gradient = nil;
    
    if ([tabBarControl isWindowActive]) {
        // gray bar gradient
        gradient = [[NSGradient alloc] initWithColorsAndLocations:
                        [NSColor colorWithCalibratedWhite:0.678 alpha:1.000],0.0f,
                        [NSColor colorWithCalibratedWhite:0.821 alpha:1.000],1.0f,
                        nil];
    } else {
        // light gray bar gradient
        gradient = [[NSGradient alloc] initWithColorsAndLocations:
                [NSColor colorWithCalibratedWhite:0.821 alpha:1.000],0.0f,
                [NSColor colorWithCalibratedWhite:0.956 alpha:1.000],1.0f,
                nil];
    }
    
    if (gradient) {
        [gradient drawInRect:bounds angle:270];
    
        [gradient release];
        }
}

- (void)drawInteriorOfTabBarControl:(PSMTabBarControl *)tabBarControl inRect:(NSRect)rect {

    // draw interior first
    [tabBarControl _drawInteriorInRect:rect];
    
    // draw separation line left and right of selected tab (no separation line at selected tab)
    for(PSMTabBarCell *cell in [tabBarControl cells]) {
        if([cell state] == NSOnState) {
            [[NSColor colorWithCalibratedWhite:0.576 alpha:1.0] set];

            [NSBezierPath strokeLineFromPoint:NSMakePoint(rect.origin.x,NSMaxY(rect)-0.5)
                toPoint:NSMakePoint(NSMinX([cell frame]),NSMaxY(rect)-0.5)];
            [NSBezierPath strokeLineFromPoint:NSMakePoint(NSMaxX([cell frame]),NSMaxY(rect)-0.5)
                toPoint:NSMakePoint(NSMaxX(rect),NSMaxY(rect)-0.5)];
        }
    }
        
}

- (void)drawBezelOfTabCell:(PSMTabBarCell *)cell withFrame:(NSRect)frame inTabBarControl:(PSMTabBarControl *)tabBarControl {

    NSRect cellFrame = [cell frame];
	
    NSColor * lineColor = nil;
    NSBezierPath *bezier = [NSBezierPath bezierPath];
    lineColor = [NSColor colorWithCalibratedWhite:0.576 alpha:1.0];

    NSRect aRect = NSMakeRect(cellFrame.origin.x+.5, cellFrame.origin.y+0.5, cellFrame.size.width-1.0, cellFrame.size.height-1.0);
    
    // frame
    CGFloat radius = MIN(6.0, 0.5f * MIN(NSWidth(aRect), NSHeight(aRect)))-0.5;

    [bezier moveToPoint: NSMakePoint(NSMinX(aRect),NSMaxY(aRect)+1.0)];
    [bezier appendBezierPathWithArcFromPoint:NSMakePoint(NSMinX(aRect),NSMinY(aRect)) toPoint:NSMakePoint(NSMidX(aRect),NSMinY(aRect)) radius:radius];
    [bezier appendBezierPathWithArcFromPoint:NSMakePoint(NSMaxX(aRect),NSMinY(aRect)) toPoint:NSMakePoint(NSMaxX(aRect),NSMaxY(aRect)) radius:radius];
    [bezier lineToPoint: NSMakePoint(NSMaxX(aRect),NSMaxY(aRect)+1.0)];
    
    NSGradient *gradient = nil;

    if([tabBarControl isWindowActive]) {
        if ([cell state] == NSOnState) {
              gradient = [[NSGradient alloc] initWithStartingColor:[NSColor whiteColor] endingColor:[NSColor colorWithDeviceWhite:0.929 alpha:1.000]];
        } else if ([cell isHighlighted]) {
        
            gradient = [[NSGradient alloc] 
                initWithStartingColor: [NSColor colorWithCalibratedWhite:0.80 alpha:1.0]
                endingColor:[NSColor colorWithCalibratedWhite:0.80 alpha:1.0]];           
        } else {

            gradient = [[NSGradient alloc] 
                initWithStartingColor:[NSColor colorWithCalibratedWhite:0.835 alpha:1.0] 
                endingColor:[NSColor colorWithCalibratedWhite:0.843 alpha:1.0]];                                
        }

        if (gradient != nil) {
            [gradient drawInBezierPath:bezier angle:90.0f];
            [gradient release], gradient = nil;
            }
    } else {
        [[NSColor windowBackgroundColor] set];
        NSRectFill(aRect);
    }
    
    [lineColor set];
    [bezier stroke];
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
