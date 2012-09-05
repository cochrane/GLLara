//
//  GLLDocumentWindowController.m
//  GLLara
//
//  Created by Torsten Kammer on 05.09.12.
//  Copyright (c) 2012 Torsten Kammer. All rights reserved.
//

#import "GLLDocumentWindowController.h"

#import "GLLBone.h"
#import "GLLBoneTransformation.h"
#import "GLLMesh.h"
#import "GLLMeshSettings.h"
#import "GLLModel.h"
#import "GLLItem.h"
#import "GLLScene.h"
#import "GLLSourceListItem.h"

@interface GLLDocumentWindowController ()

@end

static NSString *lightsGroupIdentifier = @"lights group identifier";
static NSString *itemsGroupIdentifier = @"items group identifier";
static NSString *settingsGroupIdentifier = @"settings group identifier";

@implementation GLLDocumentWindowController

- (id)initWithScene:(GLLScene *)scene;
{
    if (!(self = [super initWithWindowNibName:@"GLLDocument"])) return nil;
    
	_scene = scene;
	
	self.shouldCloseDocument = YES;
	
    return self;
}

- (void)windowDidLoad
{
    [super windowDidLoad];
	
	self.sourceView.dataSource = self;
	self.sourceView.delegate = self;
}

- (IBAction)loadMesh:(id)sender;
{
	NSOpenPanel *panel = [NSOpenPanel openPanel];
	panel.allowedFileTypes = @[ @"mesh", @"ascii" ];
	[panel beginSheetModalForWindow:self.window completionHandler:^(NSInteger result){
		if (result != NSOKButton) return;
		
		GLLModel *model = [GLLModel cachedModelFromFile:panel.URL];
		
		NSLog(@"Got model %@, with %lu bones and %lu meshes", model, model.bones.count, model.meshes.count);
		
		GLLItem *item = [[GLLItem alloc] initWithModel:model];
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

@end
