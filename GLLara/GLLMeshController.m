//
//  GLLMeshController.m
//  GLLara
//
//  Created by Torsten Kammer on 01.01.13.
//  Copyright (c) 2013 Torsten Kammer. All rights reserved.
//

#import "GLLMeshController.h"

#import "GLLItemMesh.h"

@implementation GLLMeshController

- (id)initWithMesh:(GLLItemMesh *)mesh;
{
	if (!(self = [super init])) return nil;
	
	self.mesh = mesh;
	
	return self;
}

- (void)addMeshChangeObserver:(id <GLLMeshChangeObserver>)observer;
{
	
}
- (void)removeMeshChangeObserver:(id <GLLMeshChangeObserver>)observer;
{
	
}

- (id)representedObject
{
	return self.mesh;
}

#pragma mark - Outline View Data Source

- (id)outlineView:(NSOutlineView *)outlineView child:(NSInteger)index ofItem:(id)item
{
	return nil;
}

- (id)outlineView:(NSOutlineView *)outlineView objectValueForTableColumn:(NSTableColumn *)tableColumn byItem:(id)item
{
	return self.mesh.displayName;
}

- (BOOL)outlineView:(NSOutlineView *)outlineView isItemExpandable:(id)item
{
	return NO;
}

- (NSInteger)outlineView:(NSOutlineView *)outlineView numberOfChildrenOfItem:(id)item
{
	return 0;
}

@end
