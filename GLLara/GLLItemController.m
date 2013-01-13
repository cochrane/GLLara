//
//  GLLItemController.m
//  GLLara
//
//  Created by Torsten Kammer on 17.09.12.
//  Copyright (c) 2012 Torsten Kammer. All rights reserved.
//

#import "GLLItemController.h"

#import "GLLItem.h"
#import "GLLBoneListController.h"
#import "GLLMeshListController.h"

@interface GLLItemController ()

@property (nonatomic) GLLMeshListController *meshListController;
@property (nonatomic) GLLBoneListController *boneListController;

@end

@implementation GLLItemController

- (id)initWithItem:(GLLItem *)item;
{
	if (!(self = [super init])) return nil;
	
	self.item = item;
	self.meshListController = [[GLLMeshListController alloc] initWithItem:item];
	self.boneListController = [[GLLBoneListController alloc] initWithItem:item];
		
	return self;
}

#pragma mark - Outline View Data Source

- (id)outlineView:(NSOutlineView *)outlineView child:(NSInteger)index ofItem:(id)item
{
	switch (index)
	{
		case 0: return self.meshListController;
		case 1: return self.boneListController;
		default: return nil;
	}
}

- (id)outlineView:(NSOutlineView *)outlineView objectValueForTableColumn:(NSTableColumn *)tableColumn byItem:(id)item
{
	return self.item.displayName;
}

- (void)outlineView:(NSOutlineView *)outlineView setObjectValue:(id)object forTableColumn:(NSTableColumn *)tableColumn byItem:(id)item
{
	self.item.displayName = object;
}

- (BOOL)outlineView:(NSOutlineView *)outlineView isItemExpandable:(id)item
{
	return YES;
}

- (NSInteger)outlineView:(NSOutlineView *)outlineView numberOfChildrenOfItem:(id)item
{
	return 2;
}

#pragma mark - Outline View Delegate

- (BOOL)outlineView:(NSOutlineView *)outlineView shouldEditTableColumn:(NSTableColumn *)tableColumn item:(id)item
{
	return YES;
}

@end
