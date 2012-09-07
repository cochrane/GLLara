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
#import "GLLItem.h"
#import "GLLSourceListItem.h"

@interface GLLDocumentWindowController ()
{
	GLLBoneTransformViewController *boneTransformViewController;
	GLLMeshSettingsViewController *meshSettingsViewController;
	
	NSViewController *currentController;
	NSMutableArray *allItems;
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
	
	NSFetchRequest *request = [[NSFetchRequest alloc] init];
	request.entity = [NSEntityDescription entityForName:@"GLLItem" inManagedObjectContext:_managedObjectContext];
	allItems = [NSMutableArray arrayWithArray:[_managedObjectContext executeFetchRequest:request error:NULL]];
	
	// Set up loading of future items and destroying items. Also update view.
	// Store self as weak in the block, so it does not retain this.
	__block __weak id weakSelf = self;
	managedObjectContextObserver = [[NSNotificationCenter defaultCenter] addObserverForName:NSManagedObjectContextObjectsDidChangeNotification object:_managedObjectContext queue:[NSOperationQueue mainQueue] usingBlock:^(NSNotification *notification) {
		GLLDocumentWindowController *self = weakSelf;
		
		// Remove old things
		[allItems removeObjectsInArray:[notification.userInfo[NSDeletedObjectsKey] allObjects]];
		
		// Add new things
		NSSet *newItems = [notification.userInfo[NSInsertedObjectsKey] objectsWithOptions:0 passingTest:^BOOL(NSManagedObject *object, BOOL *stop){
			return [object.entity isEqual:[NSEntityDescription entityForName:@"GLLItem" inManagedObjectContext:_managedObjectContext]];
		}];
		[allItems addObjectsFromArray:newItems.allObjects];
		
		[self.sourceView reloadItem:allItems reloadChildren:YES];
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

- (void)observeValueForKeyPath:(NSString *)keyPath ofObject:(id)object change:(NSDictionary *)change context:(void *)context
{
	if ([keyPath isEqual:@"items"])
		[self.sourceView reloadData];
	else
		[super observeValueForKeyPath:keyPath ofObject:object change:change context:context];
}

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

#pragma mark - Outline view data source

- (NSInteger)outlineView:(NSOutlineView *)outlineView numberOfChildrenOfItem:(id)item
{
	if (item == nil) // Top level
		return 3;
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
			case 0: return lightsGroupIdentifier;
			case 1: return allItems;
			case 2: return settingsGroupIdentifier;
			default: return nil;
		}
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
	if (item == lightsGroupIdentifier)
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
	return item == lightsGroupIdentifier || item == allItems || item == settingsGroupIdentifier;
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
