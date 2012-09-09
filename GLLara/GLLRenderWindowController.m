//
//  GLLRenderWindowController.m
//  GLLara
//
//  Created by Torsten Kammer on 05.09.12.
//  Copyright (c) 2012 Torsten Kammer. All rights reserved.
//

#import "GLLRenderWindowController.h"

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

- (id)initWithManagedObjectContext:(NSManagedObjectContext *)context;
{
	if (!(self = [super initWithWindowNibName:@"GLLRenderWindowController"]))
		return nil;
	
	_managedObjectContext = context;
	
	return self;
}

- (void)windowDidLoad
{
    [super windowDidLoad];
    
	self.renderView.windowController = self;
	self.popover.delegate = self;
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
		[self.popover showRelativeToRect:[sender frame] ofView:sender preferredEdge:NSMaxYEdge];
		showingPopover = YES;
	}
}

- (void)popoverDidClose:(NSNotification *)notification
{
	showingPopover = NO;
}

@end
