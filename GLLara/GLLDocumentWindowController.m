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

- (void)_setRightHandController:(NSViewController *)controller representedObject:(id)object;

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

- (void)windowDidLoad
{
    [super windowDidLoad];
	
	self.sourceView.delegate = self;
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

- (BOOL)outlineView:(NSOutlineView *)outlineView shouldSelectItem:(id)item
{
	if ([self outlineView:outlineView isGroupItem:item]) return NO;
	if ([[item representedObject] isKindOfClass:[GLLSourceListMarker class]]) return NO;
	
	return YES;
}

- (BOOL)outlineView:(NSOutlineView *)outlineView shouldEditTableColumn:(NSTableColumn *)tableColumn item:(id)item
{
	if ([item isKindOfClass:[GLLItemController class]])
		return YES;
	
	return NO;
}

#pragma mark - Private methods

- (void)_setRightHandController:(NSViewController *)controller representedObject:(id)object;
{
	if (currentController == controller)
	{
		currentController.representedObject = object;
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
		controller.representedObject = object;
		currentController = controller;
	}
}

@end
