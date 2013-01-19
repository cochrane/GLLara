//
//  GLLDocumentWindowController.m
//  GLLara
//
//  Created by Torsten Kammer on 05.09.12.
//  Copyright (c) 2012 Torsten Kammer. All rights reserved.
//

#import "GLLDocumentWindowController.h"

#import "NSArray+Map.h"
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
#import "GLLSelection.h"
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
	
	NSArrayController *selectionController;
	
	BOOL updatingSourceViewSelection;
}

- (void)_setRightHandController:(NSViewController *)controller;
- (void)_recursivelyExpandItem:(id)item;

@property (nonatomic, readonly) NSArray *allSelectableControllers;

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
	
	selectionController = [[NSArrayController alloc] init];
	[selectionController bind:@"contentArray" toObject:self withKeyPath:@"selection.selectedObjects" options:nil];
	[self addObserver:self forKeyPath:@"selection.selectedObjects" options:NSKeyValueObservingOptionNew context:NULL];
		
	self.shouldCloseDocument = YES;
	
    return self;
}

- (void)dealloc
{
	[meshViewController unbind:@"selectedMeshes"];
	[self removeObserver:self forKeyPath:@"selection.selectedObjects"];
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
		
	[meshViewController bind:@"selectedMeshes" toObject:self withKeyPath:@"selection.selectedMeshes" options:nil];
}

- (void)observeValueForKeyPath:(NSString *)keyPath ofObject:(id)object change:(NSDictionary *)change context:(void *)context
{
	if ([keyPath isEqual:@"selection.selectedObjects"])
	{
		// Set the correct selection in the outline view
		updatingSourceViewSelection = YES;
		
		NSArray *selectedOutlineViewItems = [self.allSelectableControllers filteredArrayUsingPredicate:[NSPredicate predicateWithFormat:@"representedObject in %@", self.selection.selectedObjects]];
		
		NSMutableIndexSet *selectionIndexes = [NSMutableIndexSet indexSet];
		for (id item in selectedOutlineViewItems)
		{
			[self _recursivelyExpandItem:item];
			[selectionIndexes addIndex:[self.sourceView rowForItem:item]];
		}
		
		[self.sourceView selectRowIndexes:selectionIndexes byExtendingSelection:NO];
		
		updatingSourceViewSelection = NO;
	}
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

- (void)outlineViewSelectionDidChange:(NSNotification *)notification
{
	NSArray *newSelectedObjects = [self.sourceView.selectedRowIndexes map:^(NSUInteger index){
		return [[self.sourceView itemAtRow:index] representedObject];
	}];
	
	if (!updatingSourceViewSelection)
	{
		NSMutableArray *selectedObjects = [self.selection mutableArrayValueForKey:@"selectedObjects"];
		[selectedObjects replaceObjectsInRange:NSMakeRange(0, selectedObjects.count) withObjectsFromArray:newSelectedObjects];
	}
	
	[selectionController setSelectedObjects:selectionController.arrangedObjects];
	
	if (newSelectedObjects.count == 0)
		[self _setRightHandController:nil];
	else
	{
		NSManagedObject *oneOfSelection = newSelectedObjects.lastObject;
		if ([oneOfSelection.entity isKindOfEntity:[NSEntityDescription entityForName:@"GLLAmbientLight" inManagedObjectContext:self.managedObjectContext]])
			[self _setRightHandController:ambientLightViewController];
		else if ([oneOfSelection.entity isKindOfEntity:[NSEntityDescription entityForName:@"GLLDirectionalLight" inManagedObjectContext:self.managedObjectContext]])
			[self _setRightHandController:lightViewController];
		else if ([oneOfSelection.entity isKindOfEntity:[NSEntityDescription entityForName:@"GLLItem" inManagedObjectContext:self.managedObjectContext]])
			[self _setRightHandController:itemViewController];
		else if ([oneOfSelection.entity isKindOfEntity:[NSEntityDescription entityForName:@"GLLItemMesh" inManagedObjectContext:self.managedObjectContext]])
			[self _setRightHandController:meshViewController];
		else if ([oneOfSelection.entity isKindOfEntity:[NSEntityDescription entityForName:@"GLLItemBone" inManagedObjectContext:self.managedObjectContext]])
			[self _setRightHandController:boneViewController];
		else
			[self _setRightHandController:nil];
	}
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
		currentController.representedObject = [selectionController selection];
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
		controller.representedObject = [selectionController selection];
		currentController = controller;
	}
}

- (void)_recursivelyExpandItem:(id)item;
{
	if ([item respondsToSelector:@selector(parentController)])
		[self _recursivelyExpandItem:[item parentController]];
	[self.sourceView expandItem:item];
}

- (NSArray *)allSelectableControllers
{
	NSMutableArray *result = [NSMutableArray array];
	[result addObjectsFromArray:lightsListController.allSelectableControllers];
	[result addObjectsFromArray:itemListController.allSelectableControllers];
	[result addObjectsFromArray:settingsListController.allSelectableControllers];
	return result;
}

@end
