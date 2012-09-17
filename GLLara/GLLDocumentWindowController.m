//
//  GLLDocumentWindowController.m
//  GLLara
//
//  Created by Torsten Kammer on 05.09.12.
//  Copyright (c) 2012 Torsten Kammer. All rights reserved.
//

#import "GLLDocumentWindowController.h"

#import "GLLAmbientLight.h"
#import "GLLItemBone.h"
#import "GLLBoneViewController.h"
#import "GLLItemMesh.h"
#import "GLLMeshViewController.h"
#import "GLLModel.h"
#import "GLLDirectionalLight.h"
#import "GLLItem.h"
#import "GLLItemController.h"
#import "GLLItemListController.h"
#import "GLLItemViewController.h"
#import "GLLSourceListItem.h"
#import "GLLSourceListMarker.h"

@interface GLLDocumentWindowController ()
{
	NSViewController *ambientLightViewController;
	GLLBoneViewController *boneViewController;
	GLLItemViewController *itemViewController;
	GLLMeshViewController *meshViewController;
	NSViewController *lightViewController;
	
	NSViewController *currentController;
	
	GLLItemListController *itemListController;
	NSArrayController *lightsController;
	GLLSourceListMarker *lightsMarker;
	GLLSourceListMarker *settingsMarker;
}

- (void)_setRightHandController:(NSViewController *)controller;

@end

static NSString *settingsGroupIdentifier = @"settings group identifier";

@implementation GLLDocumentWindowController

- (id)initWithManagedObjectContext:(NSManagedObjectContext *)managedObjectContext;
{
    if (!(self = [super initWithWindowNibName:@"GLLDocument"])) return nil;
    
	_managedObjectContext = managedObjectContext;
	
	ambientLightViewController = [[NSViewController alloc] initWithNibName:@"GLLAmbientLightView" bundle:[NSBundle mainBundle]];
	boneViewController = [[GLLBoneViewController alloc] init];
	itemViewController = [[GLLItemViewController alloc] init];
	meshViewController = [[GLLMeshViewController alloc] init];
	lightViewController = [[NSViewController alloc] initWithNibName:@"GLLLightView" bundle:[NSBundle mainBundle]];
	
	lightsController = [[NSArrayController alloc] initWithContent:nil];
	lightsController.managedObjectContext = self.managedObjectContext;
	lightsController.entityName = @"GLLLight";
	lightsController.automaticallyPreparesContent = YES;
	lightsController.automaticallyRearrangesObjects = YES;
	lightsController.sortDescriptors = @[ [NSSortDescriptor sortDescriptorWithKey:@"index" ascending:YES] ];
	[lightsController fetch:self];
	
	lightsMarker = [[GLLSourceListMarker alloc] initWithObject:lightsController childrenKeyPath:@"arrangedObjects"];
	lightsMarker.isSourceListHeader = YES;
	lightsMarker.sourceListDisplayName = NSLocalizedString(@"Lights", @"source list header: lights");
	
	settingsMarker = [[GLLSourceListMarker alloc] initWithObject:nil childrenKeyPath:nil];
	settingsMarker.isSourceListHeader = YES;
	settingsMarker.sourceListDisplayName = NSLocalizedString(@"Settings", @"source list header: lights");
	
	itemListController = [[GLLItemListController alloc] initWithManagedObjectContext:managedObjectContext];
		
	self.shouldCloseDocument = YES;
	
    return self;
}

- (void)dealloc
{
	[self.treeController removeObserver:self forKeyPath:@"selectedObjects"];
}

- (void)windowDidLoad
{
    [super windowDidLoad];
	
	self.sourceView.delegate = self;
	
	[self.treeController addObserver:self forKeyPath:@"selectedObjects" options:0 context:0];
}

- (void)observeValueForKeyPath:(NSString *)keyPath ofObject:(id)object change:(NSDictionary *)change context:(void *)context
{
	if ([keyPath isEqual:@"selectedObjects"])
	{
		NSArray *selected = self.treeController.selectedObjects;
		
		if (selected.count == 0)
		{
			[self _setRightHandController:nil];
			return;
		}
		
		if ([selected.lastObject isKindOfClass:[GLLAmbientLight class]])
			[self _setRightHandController:ambientLightViewController];
		else if ([selected.lastObject isKindOfClass:[GLLItemBone class]])
			[self _setRightHandController:boneViewController];
		else if ([selected.lastObject isKindOfClass:[GLLItemController class]])
			[self _setRightHandController:itemViewController];
		else if ([selected.lastObject isKindOfClass:[GLLItemMesh class]])
			[self _setRightHandController:meshViewController];
		else if ([selected.lastObject isKindOfClass:[GLLDirectionalLight class]])
			[self _setRightHandController:lightViewController];

	}
	else
		[super observeValueForKeyPath:keyPath ofObject:object change:change context:context];
}

#pragma mark - Actions

- (IBAction)removeSelectedMesh:(id)sender;
{
	NSUInteger selectedRow = self.sourceView.selectedRow;
	if (selectedRow == NSNotFound)
	{
		NSBeep();
		return;
	}
	
	id selectedObject = [self.sourceView itemAtRow:selectedRow];
	
	if ([selectedObject isKindOfClass:[GLLItemController class]])
		[self.managedObjectContext deleteObject:[selectedObject item]];
	else if ([selectedObject isKindOfClass:[GLLItemBone class]])
		[self.managedObjectContext deleteObject:[selectedObject item]];
	else if ([selectedObject isKindOfClass:[GLLItemMesh class]])
		[self.managedObjectContext deleteObject:[selectedObject item]];
	else
		NSBeep();
}

#pragma mark - Filling the tree controller

- (NSUInteger)countOfSourceListRoots;
{
	return 3;
}

- (id)objectInSourceListRootsAtIndex:(NSUInteger)index;
{
	switch(index)
	{
		case 0: return lightsMarker;
		case 1: return itemListController;
		case 2: return settingsMarker;
		default: return nil;
	}
}

#pragma mark - Outline view delegate

- (BOOL)outlineView:(NSOutlineView *)outlineView isGroupItem:(id)item
{
	return [[item valueForKeyPath:@"representedObject.isSourceListHeader"] boolValue];
}

- (NSIndexSet *)outlineView:(NSOutlineView *)outlineView selectionIndexesForProposedSelection:(NSIndexSet *)proposedSelectionIndexes;
{
	BOOL anyItemController = NO;
	NSEntityDescription *firstDescription = nil;
	
	for (NSUInteger index = proposedSelectionIndexes.firstIndex; index <= proposedSelectionIndexes.lastIndex; index = [proposedSelectionIndexes indexGreaterThanIndex:index])
	{
		id item = [[outlineView itemAtRow:index] representedObject];
		
		// Do not add source list headers
		if ([item isSourceListHeader])
			return outlineView.selectedRowIndexes;
		
		// Do not add marker objects
		if ([item isKindOfClass:[GLLSourceListMarker class]])
			return outlineView.selectedRowIndexes;
		
		if ([item isKindOfClass:[GLLItemController class]])
		{
			anyItemController = YES;
			
			// Do not add controllers if there are already objects in…
			if (firstDescription)
				return outlineView.selectedRowIndexes;
		}
		else
		{
			// …and vice versa
			if (anyItemController)
				return outlineView.selectedRowIndexes;
			
			// Reject if any object has a type unlike the others.
			NSEntityDescription *entity = [item entity];
			if (!firstDescription)
				firstDescription = entity;
			else if (![entity isEqual:firstDescription])
				return outlineView.selectedRowIndexes;
		}
	}
	
	return proposedSelectionIndexes;
}

- (BOOL)outlineView:(NSOutlineView *)outlineView shouldEditTableColumn:(NSTableColumn *)tableColumn item:(id)item
{
	if ([item isKindOfClass:[GLLItemController class]])
		return YES;
	
	return NO;
}

#pragma mark - Private methods

- (void)_setRightHandController:(NSViewController *)controller;
{
	/*
	 * This code first sets the represented object to nil, then to the selection, even if nothing seems to have changed. This is because otherwise, the object controllers don't notice that the contents of the selection of the array controller has changed (Someone should really write a bug report about this, by the way). Setting it again to the original value will be ignored, so it has to be set to something else (like nil) in between.
	 */
	currentController.representedObject = nil;
	
	if (currentController == controller)
	{
		currentController.representedObject = self.treeController.selection;
		return;
	}
	
	if (currentController)
	{
		[currentController.view removeFromSuperview];
		currentController = nil;
	}
	
	if (controller)
	{
		NSView *newView = controller.view;
		newView.frame = (NSRect) { { 0.0f, 0.0f }, self.placeholderView.frame.size };
		[self.placeholderView addSubview:controller.view];
		controller.representedObject = self.treeController.selection;
		currentController = controller;
	}
}

@end
