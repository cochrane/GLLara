//
//  GLLMeshListController.m
//  GLLara
//
//  Created by Torsten Kammer on 13.01.13.
//  Copyright (c) 2013 Torsten Kammer. All rights reserved.
//

#import "GLLMeshListController.h"

#import "NSArray+Map.h"
#import "GLLItem.h"
#import "GLLMeshController.h"

@interface GLLMeshListController ()

@property (nonatomic) NSArray<GLLMeshController *> *meshControllers;

@end

@implementation GLLMeshListController

- (id)initWithItem:(GLLItem *)item parent:(id)parentController;
{
	if (!(self = [super init])) return nil;
	
	self.item = item;
	self.parentController = parentController;	
	self.meshControllers = [self.item.meshes map:^(GLLItemMesh *mesh){
		return [[GLLMeshController alloc] initWithMesh:mesh parentController:self];
	}];
	
	return self;
}

- (NSArray *)allSelectableControllers
{
	return self.meshControllers;
}

#pragma mark - Outline View Data Source

- (id)outlineView:(NSOutlineView *)outlineView child:(NSInteger)index ofItem:(id)item
{
	return self.meshControllers[index];
}

- (id)outlineView:(NSOutlineView *)outlineView objectValueForTableColumn:(NSTableColumn *)tableColumn byItem:(id)item
{
	return NSLocalizedString(@"Meshes", @"source view header");
}

- (BOOL)outlineView:(NSOutlineView *)outlineView isItemExpandable:(id)item
{
	return YES;
}

- (NSInteger)outlineView:(NSOutlineView *)outlineView numberOfChildrenOfItem:(id)item
{
	return self.meshControllers.count;
}

#pragma mark - Outline View Delegate

- (BOOL)outlineView:(NSOutlineView *)outlineView shouldSelectItem:(id)item
{
	return NO;
}

@end
