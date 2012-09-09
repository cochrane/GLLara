//
//  GLLRenderWindowController.m
//  GLLara
//
//  Created by Torsten Kammer on 05.09.12.
//  Copyright (c) 2012 Torsten Kammer. All rights reserved.
//

#import "GLLRenderWindowController.h"

#import <AppKit/NSWindow.h>
#import <AppKit/NSView.h>
#import <AppKit/NSViewController.h>

#import "GLLCamera.h"
#import "GLLView.h"
#import "GLLSceneDrawer.h"

@interface GLLRenderWindowController ()
{
	GLLSceneDrawer *drawer;
	BOOL showingPopover;
}

@end

@implementation GLLRenderWindowController

+ (NSSet *)keyPathsForValuesAffectingTargetsFilterPredicate
{
	return [NSSet setWithObjects:@"itemsController.arrangedObjects", @"selelctedItemIndex", nil];
}

- (id)initWithCamera:(GLLCamera *)camera;
{
	if (!(self = [super initWithWindowNibName:@"GLLRenderWindowController"]))
		return nil;
	
	_camera = camera;
	
	return self;
}

- (void)windowDidLoad
{
    [super windowDidLoad];
    
	self.renderView.camera = self.camera;
	self.renderView.windowController = self;
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
		[self.window setContentSize:NSMakeSize([change[NSKeyValueChangeNewKey] doubleValue], contentSize.height)];
	}
	else if ([keyPath isEqual:@"windowHeight"])
	{
		[self.window setContentSize:NSMakeSize(contentSize.width, [change[NSKeyValueChangeNewKey] doubleValue])];
	}
	else if ([keyPath isEqual:@"windowSizeLocked"])
	{
		NSUInteger styleMask = self.window.styleMask;
		styleMask = styleMask & ~NSResizableWindowMask; // Clear resizable window mask bit (if it was set)
		if (![change[NSKeyValueChangeNewKey] boolValue])
			styleMask = styleMask & NSResizableWindowMask; // Set it
		self.window.styleMask = styleMask;
	}
	
}

- (NSManagedObjectContext *)managedObjectContext
{
	return self.camera.managedObjectContext;
}

- (NSString *)windowTitleForDocumentDisplayName:(NSString *)displayName
{
	return [NSString stringWithFormat:NSLocalizedString(@"%@ - Render view", @"render window title format"), displayName];
}

- (void)openGLPrepared;
{
	drawer = [[GLLSceneDrawer alloc] initWithManagedObjectContext:self.managedObjectContext view:self.renderView];
}

- (NSPredicate *)targetsFilterPredicate
{
	return [NSComparisonPredicate predicateWithLeftExpression:[NSExpression expressionForKeyPath:@"bones.item"] rightExpression:[NSExpression expressionForConstantValue:self.selectedObject]  modifier:NSAnyPredicateModifier type:NSEqualToPredicateOperatorType options:0];
}

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

@end
