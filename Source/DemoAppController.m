#import "DemoAppController.h"
#import "DemoWindowController.h"


@implementation DemoAppController

- (void)applicationDidFinishLaunching:(NSNotification *)pNotification {
	[self newWindow:self];
	[self newWindow:self];
	NSRect frontFrame = [[NSApp keyWindow] frame];
	frontFrame.origin.x += 400;
	[[NSApp keyWindow] setFrame:frontFrame display:YES];
}
- (IBAction)newWindow:(id)sender {
	// put up a window
	DemoWindowController *newWindow = [[DemoWindowController alloc] initWithWindowNibName:@"DemoWindow"];
	[newWindow showWindow:self];
	[newWindow addDefaultTabs];
}

@end
