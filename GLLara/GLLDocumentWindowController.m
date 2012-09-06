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
#import "GLLScene.h"
#import "GLLSourceListItem.h"

@interface GLLDocumentWindowController ()
{
	GLLBoneTransformViewController *boneTransformViewController;
	GLLMeshSettingsViewController *meshSettingsViewController;
	
	NSViewController *currentController;
}

- (void)_setRightHandController:(NSViewController *)controller representedObject:(id)object;

@end

static NSString *lightsGroupIdentifier = @"lights group identifier";
static NSString *itemsGroupIdentifier = @"items group identifier";
static NSString *settingsGroupIdentifier = @"settings group identifier";

@implementation GLLDocumentWindowController

- (id)initWithScene:(GLLScene *)scene;
{
    if (!(self = [super initWithWindowNibName:@"GLLDocument"])) return nil;
    
	_scene = scene;
	
	boneTransformViewController = [[GLLBoneTransformViewController alloc] init];
	meshSettingsViewController = [[GLLMeshSettingsViewController alloc] init];
	
	self.shouldCloseDocument = YES;
	
    return self;
}

- (void)dealloc
{
	[_scene removeObserver:self forKeyPath:@"items"];
}

- (void)windowDidLoad
{
    [super windowDidLoad];
	
	self.sourceView.dataSource = self;
	self.sourceView.delegate = self;
	
	[_scene addObserver:self forKeyPath:@"items" options:0 context:NULL];
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
		
		GLLItem *item = [[GLLItem alloc] initWithModel:model scene:self.scene];
		NSLog(@"got item %@", item);
		
		[[self.scene mutableArrayValueForKey:@"items"] addObject:item];
	}];
}

#pragma mark - Outline view data source

- (NSInteger)outlineView:(NSOutlineView *)outlineView numberOfChildrenOfItem:(id)item
{
	if (item == nil) // Top level
		return 3;
	else if (item == itemsGroupIdentifier)
		return self.scene.items.count;
	else if ([item conformsToProtocol:@protocol(GLLSourceListItem)])
		return [item numberOfChildrenInSourceList];
	
	return 0;
}

- (BOOL)outlineView:(NSOutlineView *)outlineView isItemExpandable:(id)item
{
	if (item == itemsGroupIdentifier)
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
			case 1: return itemsGroupIdentifier;
			case 2: return settingsGroupIdentifier;
			default: return nil;
		}
	}
	else if (item == itemsGroupIdentifier)
	{
		return self.scene.items[index];
	}
	else if ([item conformsToProtocol:@protocol(GLLSourceListItem)])
		return [item childInSourceListAtIndex:index];
	
	return nil;
}

- (id)outlineView:(NSOutlineView *)outlineView objectValueForTableColumn:(NSTableColumn *)tableColumn byItem:(id)item
{
	if (item == lightsGroupIdentifier)
		return NSLocalizedString(@"Lights", @"lights source list header");
	else if (item == itemsGroupIdentifier)
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
	return item == lightsGroupIdentifier || item == itemsGroupIdentifier || item == settingsGroupIdentifier;
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
