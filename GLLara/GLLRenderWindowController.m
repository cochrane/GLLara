//
//  GLLRenderWindowController.m
//  GLLara
//
//  Created by Torsten Kammer on 05.09.12.
//  Copyright (c) 2012 Torsten Kammer. All rights reserved.
//

#import "GLLRenderWindowController.h"

#import "GLLCamera.h"
#import "GLLView.h"
#import "GLLRenderAccessoryViewController.h"
#import "GLLSceneDrawer.h"

@interface GLLRenderWindowController ()
{
	GLLRenderAccessoryViewController *savePanelAccessoryViewController;
	BOOL showingPopover;
}

@property (nonatomic, retain, readwrite) GLLCamera *camera;

@end

@implementation GLLRenderWindowController

- (id)initWithCamera:(GLLCamera *)camera;
{
	if (!(self = [super initWithWindowNibName:@"GLLRenderWindowController"]))
		return nil;
	
	_camera = camera;
	savePanelAccessoryViewController = [[GLLRenderAccessoryViewController alloc] init];
	
	return self;
}

- (void)windowDidLoad
{
    [super windowDidLoad];
	
	[self.popoverButton.image setTemplate:YES];
	
	self.window.delegate = self;
    
	self.renderView.camera = self.camera;
	self.popover.delegate = self;
	
	[self.camera addObserver:self forKeyPath:@"windowWidth" options:NSKeyValueObservingOptionNew | NSKeyValueObservingOptionInitial
					 context:NULL];
	[self.camera addObserver:self forKeyPath:@"windowHeight" options:NSKeyValueObservingOptionNew | NSKeyValueObservingOptionInitial
					 context:NULL];
	[self.camera addObserver:self forKeyPath:@"windowSizeLocked" options:NSKeyValueObservingOptionNew | NSKeyValueObservingOptionInitial
					 context:NULL];
}

- (void)observeValueForKeyPath:(NSString *)keyPath ofObject:(id)object change:(NSDictionary *)change context:(void *)context
{
	NSSize contentSize = [self.window.contentView frame].size;
	
	if ([keyPath isEqual:@"windowWidth"])
	{
		if ([change[NSKeyValueChangeNewKey] isKindOfClass:[NSNull class]])
		{
			[self close];
			return;
		}
		[self.window setContentSize:NSMakeSize([change[NSKeyValueChangeNewKey] doubleValue], contentSize.height)];
	}
	else if ([keyPath isEqual:@"windowHeight"])
	{
		if ([change[NSKeyValueChangeNewKey] isKindOfClass:[NSNull class]])
		{
			[self close];
			return;
		}
		[self.window setContentSize:NSMakeSize(contentSize.width, [change[NSKeyValueChangeNewKey] doubleValue])];
	}
	else if ([keyPath isEqual:@"windowSizeLocked"])
	{
		if ([change[NSKeyValueChangeNewKey] isKindOfClass:[NSNull class]])
		{
			[self close];
			return;
		}
		NSUInteger styleMask = self.window.styleMask;
		styleMask = styleMask & ~NSResizableWindowMask; // Clear resizable window mask bit (if it was set)
		if (![change[NSKeyValueChangeNewKey] boolValue])
			styleMask = styleMask | NSResizableWindowMask; // Set it
		self.window.styleMask = styleMask;
	}
	else
		[super observeValueForKeyPath:keyPath ofObject:object change:change context:0];
}

- (NSManagedObjectContext *)managedObjectContext
{
	return self.camera.managedObjectContext;
}

- (NSString *)windowTitleForDocumentDisplayName:(NSString *)displayName
{
	return [NSString stringWithFormat:NSLocalizedString(@"%@ - Render view %lu", @"render window title format"), displayName, self.camera.index + 1];
}

#pragma mark - Popover

- (IBAction)showPopoverFrom:(id)sender;
{
	if (showingPopover)
		[self.popover close];
	else
	{
		self.popover.contentViewController.representedObject = self.camera;
		[self.popover showRelativeToRect:[sender frame] ofView:sender preferredEdge:NSMaxYEdge];
		showingPopover = YES;
	}
}

- (void)popoverDidClose:(NSNotification *)notification
{
	showingPopover = NO;
}

#pragma mark - Window delegate

- (BOOL)windowShouldClose:(id)sender
{
	[self.camera removeObserver:self forKeyPath:@"windowWidth"];
	[self.camera removeObserver:self forKeyPath:@"windowHeight"];
	[self.camera removeObserver:self forKeyPath:@"windowSizeLocked"];
	self.renderView.camera = nil;
	
	[self.managedObjectContext deleteObject:self.camera];
	
	self.camera = nil;
	
	return YES;
}

- (void)windowWillClose:(NSNotification *)notification
{
	[self.camera removeObserver:self forKeyPath:@"windowWidth"];
	[self.camera removeObserver:self forKeyPath:@"windowHeight"];
	[self.camera removeObserver:self forKeyPath:@"windowSizeLocked"];
	self.renderView.camera = nil;
	self.camera = nil;
}

- (IBAction)renderToFile:(id)sender
{
	NSMutableDictionary *saveData = [NSMutableDictionary dictionaryWithDictionary:@{
									 @"width" : @(self.camera.actualWindowWidth),
									 @"height" : @(self.camera.actualWindowHeight),
									 @"maxSamples" : @8,
									 }];
	
	NSSavePanel *savePanel = [NSSavePanel savePanel];
	savePanelAccessoryViewController.representedObject = saveData;
	savePanelAccessoryViewController.savePanel = savePanel;
	savePanel.accessoryView = savePanelAccessoryViewController.view;
	
	savePanel.allowedFileTypes = (__bridge_transfer NSArray *) CGImageDestinationCopyTypeIdentifiers();
	
	[savePanel beginSheetModalForWindow:self.window completionHandler:^(NSInteger result){
		if (result != NSOKButton) return;
		
		NSUInteger width = [saveData[@"width"] unsignedIntegerValue];
		NSUInteger height = [saveData[@"height"] unsignedIntegerValue];
		
		[self.renderView.sceneDrawer writeImageToURL:savePanel.URL fileType:savePanelAccessoryViewController.selectedTypeIdentifier size:CGSizeMake(width, height)];
	}];
}

@end
