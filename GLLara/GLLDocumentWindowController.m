//
//  GLLDocumentWindowController.m
//  GLLara
//
//  Created by Torsten Kammer on 05.09.12.
//  Copyright (c) 2012 Torsten Kammer. All rights reserved.
//

#import "GLLDocumentWindowController.h"

#import "GLLBoneTransformation.h"
#import "GLLBoneTransformViewController.h"
#import "GLLMeshSettings.h"
#import "GLLMeshSettingsViewController.h"
#import "GLLModel.h"
#import "GLLLight.h"
#import "GLLLightViewController.h"
#import "GLLItem.h"
#import "GLLSourceListItem.h"

@interface GLLDocumentWindowController ()
{
	GLLBoneTransformViewController *boneTransformViewController;
	GLLMeshSettingsViewController *meshSettingsViewController;
	GLLLightViewController *lightViewController;
	
	NSViewController *currentController;
	NSMutableArray *allItems;
	NSMutableArray *allLights;
	id managedObjectContextObserver;
}

- (void)_setRightHandController:(NSViewController *)controller representedObject:(id)object;

@end

static NSString *lightsGroupIdentifier = @"lights group identifier";
static NSString *settingsGroupIdentifier = @"settings group identifier";

@implementation GLLDocumentWindowController

- (id)initWithManagedObjectContext:(NSManagedObjectContext *)managedObjectContext;
{
    if (!(self = [super initWithWindowNibName:@"GLLDocument"])) return nil;
    
	_managedObjectContext = managedObjectContext;
	
	boneTransformViewController = [[GLLBoneTransformViewController alloc] init];
	meshSettingsViewController = [[GLLMeshSettingsViewController alloc] init];
	lightViewController = [[GLLLightViewController alloc] init];
	
	NSFetchRequest *itemsRequest = [[NSFetchRequest alloc] init];
	itemsRequest.entity = [NSEntityDescription entityForName:@"GLLItem" inManagedObjectContext:_managedObjectContext];
	allItems = [NSMutableArray arrayWithArray:[_managedObjectContext executeFetchRequest:itemsRequest error:NULL]];
	
	NSFetchRequest *lightsRequest = [[NSFetchRequest alloc] init];
	lightsRequest.entity = [NSEntityDescription entityForName:@"GLLLight" inManagedObjectContext:_managedObjectContext];
	lightsRequest.sortDescriptors = @[ [NSSortDescriptor sortDescriptorWithKey:@"index" ascending:YES] ];
	allLights = [NSMutableArray arrayWithArray:[_managedObjectContext executeFetchRequest:lightsRequest error:NULL]];
	
	// Set up loading of future items and destroying items. Also update view.
	// Store self as weak in the block, so it does not retain this.
	__block __weak id weakSelf = self;
	managedObjectContextObserver = [[NSNotificationCenter defaultCenter] addObserverForName:NSManagedObjectContextObjectsDidChangeNotification object:_managedObjectContext queue:[NSOperationQueue mainQueue] usingBlock:^(NSNotification *notification) {
		GLLDocumentWindowController *self = weakSelf;
		
		// Remove old things
		[allItems removeObjectsInArray:[notification.userInfo[NSDeletedObjectsKey] allObjects]];
		[allLights removeObjectsInArray:[notification.userInfo[NSDeletedObjectsKey] allObjects]];
		
		// Add new things
		NSSet *newItems = [notification.userInfo[NSInsertedObjectsKey] objectsWithOptions:0 passingTest:^BOOL(NSManagedObject *object, BOOL *stop){
			return [object.entity isEqual:[NSEntityDescription entityForName:@"GLLItem" inManagedObjectContext:_managedObjectContext]];
		}];
		[allItems addObjectsFromArray:newItems.allObjects];
		
		// Add new things
		NSSet *newLights = [notification.userInfo[NSInsertedObjectsKey] objectsWithOptions:0 passingTest:^BOOL(NSManagedObject *object, BOOL *stop){
			return [object.entity isEqual:[NSEntityDescription entityForName:@"GLLLight" inManagedObjectContext:_managedObjectContext]];
		}];
		[allLights addObjectsFromArray:newLights.allObjects];
		[allLights sortUsingDescriptors:@[ [NSSortDescriptor sortDescriptorWithKey:@"index" ascending:YES] ]];
		
		[self.sourceView reloadItem:allItems reloadChildren:YES];
		[self.sourceView reloadItem:allLights reloadChildren:YES];
	}];
	
	self.shouldCloseDocument = YES;
	
    return self;
}

- (void)dealloc
{
	[[NSNotificationCenter defaultCenter] removeObserver:managedObjectContextObserver];
}

- (void)windowDidLoad
{
    [super windowDidLoad];
	
	self.sourceView.dataSource = self;
	self.sourceView.delegate = self;
}

#pragma mark - Actions

- (IBAction)loadMesh:(id)sender;
{
	NSOpenPanel *panel = [NSOpenPanel openPanel];
	panel.allowedFileTypes = @[ @"mesh", @"ascii" ];
	[panel beginSheetModalForWindow:self.window completionHandler:^(NSInteger result){
		if (result != NSOKButton) return;
		
		GLLModel *model = [GLLModel cachedModelFromFile:panel.URL];
		
		NSLog(@"Got model %@, with %lu bones and %lu meshes", model, model.bones.count, model.meshes.count);
		
		
		GLLItem *newItem = [NSEntityDescription insertNewObjectForEntityForName:@"GLLItem" inManagedObjectContext:self.managedObjectContext];
		newItem.model = model;
	}];
}
- (IBAction)removeSelectedMesh:(id)sender;
{
	NSUInteger selectedRow = self.sourceView.selectedRow;
	if (selectedRow == NSNotFound)
	{
		NSBeep();
		return;
	}
	
	id selectedObject = [self.sourceView itemAtRow:selectedRow];
	
	if ([selectedObject isKindOfClass:[GLLItem class]])
		[self.managedObjectContext deleteObject:selectedObject];
	else if ([selectedObject isKindOfClass:[GLLBoneTransformation class]])
		[self.managedObjectContext deleteObject:[selectedObject item]];
	else if ([selectedObject isKindOfClass:[GLLMeshSettings class]])
		[self.managedObjectContext deleteObject:[selectedObject item]];
	else
		NSBeep();
}

#pragma mark - Outline view data source

- (NSInteger)outlineView:(NSOutlineView *)outlineView numberOfChildrenOfItem:(id)item
{
	if (item == nil) // Top level
		return 3;
	else if (item == allLights)
		return allLights.count;
	else if (item == allItems)
		return allItems.count;
	else if ([item conformsToProtocol:@protocol(GLLSourceListItem)])
		return [item numberOfChildrenInSourceList];
	
	return 0;
}

- (BOOL)outlineView:(NSOutlineView *)outlineView isItemExpandable:(id)item
{
	if (item == allItems)
		return YES;
	else if (item == allLights)
		return YES;
	else if ([item conformsToProtocol:@protocol(GLLSourceListItem)])
		return [item hasChildrenInSourceList];
	
	return NO;
}

- (id)outlineView:(NSOutlineView *)outlineView child:(NSInteger)index ofItem:(id)item
{
	if (item == nil)
	{
		switch(index)
		{
			case 0: return allLights;
			case 1: return allItems;
			case 2: return settingsGroupIdentifier;
			default: return nil;
		}
	}
	else if (item == allLights)
	{
		return allLights[index];
	}
	else if (item == allItems)
	{
		return allItems[index];
	}
	else if ([item conformsToProtocol:@protocol(GLLSourceListItem)])
		return [item childInSourceListAtIndex:index];
	
	return nil;
}

- (id)outlineView:(NSOutlineView *)outlineView objectValueForTableColumn:(NSTableColumn *)tableColumn byItem:(id)item
{
	if (item == allLights)
		return NSLocalizedString(@"Lights", @"lights source list header");
	else if (item == allItems)
		return NSLocalizedString(@"Items", @"items source list header");
	else if (item == settingsGroupIdentifier)
		return NSLocalizedString(@"Settings", @"settings source list header");
	
	else if ([item conformsToProtocol:@protocol(GLLSourceListItem)])
		return [item sourceListDisplayName];
	
	return nil;
}

#pragma mark - Outline view delegate

- (BOOL)outlineView:(NSOutlineView *)outlineView isGroupItem:(id)item
{
	return item == allLights || item == allItems || item == settingsGroupIdentifier;
}

- (void)outlineViewSelectionDidChange:(NSNotification *)notification
{
	NSUInteger selectedRow = self.sourceView.selectedRow;
	if (selectedRow == NSNotFound)
	{
		[self _setRightHandController:nil representedObject:nil];
		return;
	}
	
	id selectedObject = [self.sourceView itemAtRow:selectedRow];
	if ([selectedObject isKindOfClass:[GLLBoneTransformation class]])
		[self _setRightHandController:boneTransformViewController representedObject:selectedObject];
	else if ([selectedObject isKindOfClass:[GLLMeshSettings class]])
		[self _setRightHandController:meshSettingsViewController representedObject:selectedObject];
	else if ([selectedObject isKindOfClass:[GLLLight class]])
		[self _setRightHandController:lightViewController representedObject:selectedObject];
	else
		[self _setRightHandController:nil representedObject:nil];
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
