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
#import "GLLDocument.h"
#import "GLLItem.h"
#import "GLLItem+OBJExport.h"
#import "GLLItemController.h"
#import "GLLItemExportViewController.h"
#import "GLLItemListController.h"
#import "GLLItemViewController.h"
#import "GLLLightsListController.h"
#import "GLLItemListController.h"
#import "GLLSettingsListController.h"

@interface GLLDocumentWindowController ()
{
	NSViewController *ambientLightViewController;
	GLLBoneViewController *boneViewController;
	GLLItemViewController *itemViewController;
	GLLMeshViewController *meshViewController;
	NSViewController *lightViewController;
	
	GLLLightsListController *lightsListController;
	GLLItemListController *itemListController;
	GLLSettingsListController *settingsListController;
	
	NSViewController *currentController;
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
		
	self.shouldCloseDocument = YES;
	
    return self;
}

- (void)dealloc
{
	[meshViewController unbind:@"selectedObjects"];
}

- (void)windowDidLoad
{
    [super windowDidLoad];
	
	lightsListController = [[GLLLightsListController alloc] initWithManagedObjectContext:self.managedObjectContext outlineView:self.sourceView];
	itemListController = [[GLLItemListController alloc] initWithManagedObjectContext:self.managedObjectContext outlineView:self.sourceView];
	settingsListController = [[GLLSettingsListController alloc] initWithManagedObjectContext:self.managedObjectContext outlineView:self.sourceView];
	
	self.sourceView.delegate = self;
	self.sourceView.dataSource = self;
	
	[self.sourceView expandItem:lightsListController];
	[self.sourceView expandItem:itemListController];
	[self.sourceView expandItem:settingsListController];
		
//	[meshViewController bind:@"selectedObjects" toObject:self withKeyPath:@"treeController.selectedObjects" options:nil];
}

- (void)observeValueForKeyPath:(NSString *)keyPath ofObject:(id)object change:(NSDictionary *)change context:(void *)context
{
	if ([keyPath isEqual:@"selectedObjects"])
	{
//		NSArray *selected = self.treeController.selectedObjects;
//		
//		if (selected.count == 0)
//		{
//			[self _setRightHandController:nil];
//			return;
//		}
//		
//		if ([selected.lastObject isKindOfClass:[GLLAmbientLight class]])
//			[self _setRightHandController:ambientLightViewController];
//		else if ([selected.lastObject isKindOfClass:[GLLItemBone class]])
//			[self _setRightHandController:boneViewController];
//		else if ([selected.lastObject isKindOfClass:[GLLItemController class]])
//			[self _setRightHandController:itemViewController];
//		else if ([selected.lastObject isKindOfClass:[GLLItemMesh class]])
//			[self _setRightHandController:meshViewController];
//		else if ([selected.lastObject isKindOfClass:[GLLDirectionalLight class]])
//			[self _setRightHandController:lightViewController];
		
	}
	else
		[super observeValueForKeyPath:keyPath ofObject:object change:change context:context];
}

#pragma mark - Outline view data source

- (id)outlineView:(NSOutlineView *)outlineView child:(NSInteger)index ofItem:(id)item
{
	if (item) return [item outlineView:outlineView child:index ofItem:item];
	
	switch (index)
	{
		case 0: return lightsListController;
		case 1: return itemListController;
		case 2: return settingsListController;
		default: return nil;
	}
}

- (id)outlineView:(NSOutlineView *)outlineView objectValueForTableColumn:(NSTableColumn *)tableColumn byItem:(id)item
{
	if (item) return [item outlineView:outlineView objectValueForTableColumn:tableColumn byItem:item];
	
	return nil;
}

- (void)outlineView:(NSOutlineView *)outlineView setObjectValue:(id)object forTableColumn:(NSTableColumn *)tableColumn byItem:(id)item
{
	if ([item respondsToSelector:_cmd])
		[item outlineView:outlineView setObjectValue:object forTableColumn:tableColumn byItem:item];
}

- (BOOL)outlineView:(NSOutlineView *)outlineView isItemExpandable:(id)item
{
	if (item == nil) return YES;
	else return [item outlineView:outlineView isItemExpandable:item];
}

- (NSInteger)outlineView:(NSOutlineView *)outlineView numberOfChildrenOfItem:(id)item
{
	if (item == nil) return 3;
	else return [item outlineView:outlineView numberOfChildrenOfItem:item];
}

#pragma mark - Outline view delegate

- (BOOL)outlineView:(NSOutlineView *)outlineView isGroupItem:(id)item
{
	if ([item respondsToSelector:_cmd])
		return [item outlineView:outlineView isGroupItem:item];
	return NO;
}

- (NSIndexSet *)outlineView:(NSOutlineView *)outlineView selectionIndexesForProposedSelection:(NSIndexSet *)proposedSelectionIndexes;
{
	Class firstClass = Nil;
	
	for (NSUInteger index = proposedSelectionIndexes.firstIndex; index <= proposedSelectionIndexes.lastIndex; index = [proposedSelectionIndexes indexGreaterThanIndex:index])
	{
		id item = [outlineView itemAtRow:index];
		
		// Check whether item does not want to be selected
		if ([item respondsToSelector:@selector(outlineView:shouldSelectItem:)])
		{
			if (![item outlineView:outlineView shouldSelectItem:item])
				return outlineView.selectedRowIndexes;
		}
		
		Class current = [item class];
		if (!firstClass) firstClass = current;
		if (firstClass != current) return outlineView.selectedRowIndexes;
	}
	
	return proposedSelectionIndexes;
}

- (BOOL)outlineView:(NSOutlineView *)outlineView shouldEditTableColumn:(NSTableColumn *)tableColumn item:(id)item
{
	if ([item respondsToSelector:_cmd])
		return [item outlineView:outlineView shouldEditTableColumn:tableColumn item:item];
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
//		currentController.representedObject = self.treeController.selection;
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
//		controller.representedObject = self.treeController.selection;
		currentController = controller;
	}
}

@end
