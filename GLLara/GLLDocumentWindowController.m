//
//  GLLDocumentWindowController.m
//  GLLara
//
//  Created by Torsten Kammer on 05.09.12.
//  Copyright (c) 2012 Torsten Kammer. All rights reserved.
//

#import "GLLDocumentWindowController.h"

#import "GLLAmbientLight.h"
#import "GLLAmbientLightViewController.h"
#import "GLLBoneTransformation.h"
#import "GLLBoneTransformViewController.h"
#import "GLLMeshSettings.h"
#import "GLLMeshSettingsViewController.h"
#import "GLLModel.h"
#import "GLLDirectionalLight.h"
#import "GLLLightViewController.h"
#import "GLLItem.h"
#import "GLLSourceListItem.h"

@interface GLLDocumentWindowController ()
{
	GLLAmbientLightViewController *ambientLightViewController;
	GLLBoneTransformViewController *boneTransformViewController;
	GLLMeshSettingsViewController *meshSettingsViewController;
	GLLLightViewController *lightViewController;
	
	NSViewController *currentController;
	
	NSArrayController *lightsController;
	NSArrayController *itemsController;
}

- (void)_setRightHandController:(NSViewController *)controller representedObject:(id)object;

@end

static NSString *settingsGroupIdentifier = @"settings group identifier";

@implementation GLLDocumentWindowController

- (id)initWithManagedObjectContext:(NSManagedObjectContext *)managedObjectContext;
{
    if (!(self = [super initWithWindowNibName:@"GLLDocument"])) return nil;
    
	_managedObjectContext = managedObjectContext;
	
	ambientLightViewController = [[GLLAmbientLightViewController alloc] init];
	boneTransformViewController = [[GLLBoneTransformViewController alloc] init];
	meshSettingsViewController = [[GLLMeshSettingsViewController alloc] init];
	lightViewController = [[GLLLightViewController alloc] init];
	
	
	lightsController = [[NSArrayController alloc] initWithContent:nil];
	lightsController.managedObjectContext = self.managedObjectContext;
	lightsController.entityName = @"GLLLight";
	lightsController.automaticallyPreparesContent = YES;
	lightsController.automaticallyRearrangesObjects = YES;
	lightsController.sortDescriptors = @[ [NSSortDescriptor sortDescriptorWithKey:@"index" ascending:YES] ];
	[lightsController fetch:self];
	
	itemsController = [[NSArrayController alloc] initWithContent:nil];
	itemsController.managedObjectContext = self.managedObjectContext;
	itemsController.entityName = @"GLLItem";
	itemsController.automaticallyPreparesContent = YES;
	itemsController.automaticallyRearrangesObjects = YES;
	[itemsController fetch:self];
	
	// Using __bridge because for the entire time this observation happens, the controllers get retained by this class anyway.
	[lightsController addObserver:self forKeyPath:@"arrangedObjects" options:0 context:(__bridge void *) lightsController];
	[itemsController addObserver:self forKeyPath:@"arrangedObjects" options:0 context:(__bridge void *) itemsController];
	
	self.shouldCloseDocument = YES;
	
    return self;
}

- (void)dealloc
{
	[lightsController removeObserver:self forKeyPath:@"arrangedObjects"];
	[itemsController removeObserver:self forKeyPath:@"arrangedObjects"];
}

- (void)observeValueForKeyPath:(NSString *)keyPath ofObject:(id)object change:(NSDictionary *)change context:(void *)context
{
	if ([keyPath isEqual:@"arrangedObjects"])
		[self.sourceView reloadItem:(__bridge id) context reloadChildren:YES];
	else
		[super observeValueForKeyPath:keyPath ofObject:object change:change context:context];
}

- (void)windowDidLoad
{
    [super windowDidLoad];
	
	[self.window setContentBorderThickness:20.0 forEdge:NSMinYEdge];
	
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
		
		NSError *error = nil;
		GLLModel *model = [GLLModel cachedModelFromFile:panel.URL error:&error];
		
		if (!model)
		{
			[self.window presentError:error];
			return;
		}
				
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
	else if ([item isKindOfClass:[NSArrayController class]])
		return [[item arrangedObjects] count];
	else if ([item conformsToProtocol:@protocol(GLLSourceListItem)])
		return [item numberOfChildrenInSourceList];
	
	return 0;
}

- (BOOL)outlineView:(NSOutlineView *)outlineView isItemExpandable:(id)item
{
	if ([item isKindOfClass:[NSArrayController class]])
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
			case 0: return lightsController;
			case 1: return itemsController;
			case 2: return settingsGroupIdentifier;
			default: return nil;
		}
	}
	else if ([item isKindOfClass:[NSArrayController class]])
		return [[item arrangedObjects] objectAtIndex:index];
	else if ([item conformsToProtocol:@protocol(GLLSourceListItem)])
		return [item childInSourceListAtIndex:index];
	
	return nil;
}

- (id)outlineView:(NSOutlineView *)outlineView objectValueForTableColumn:(NSTableColumn *)tableColumn byItem:(id)item
{
	if (item == lightsController)
		return NSLocalizedString(@"Lights", @"lights source list header");
	else if (item == itemsController)
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
	return item == lightsController || item == itemsController || item == settingsGroupIdentifier;
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
	else if ([selectedObject isKindOfClass:[GLLDirectionalLight class]])
		[self _setRightHandController:lightViewController representedObject:selectedObject];
	else if ([selectedObject isKindOfClass:[GLLAmbientLight class]])
		[self _setRightHandController:ambientLightViewController representedObject:selectedObject];
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
