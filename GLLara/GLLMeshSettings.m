//
//  GLLMeshSettings.m
//  GLLara
//
//  Created by Torsten Kammer on 05.09.12.
//  Copyright (c) 2012 Torsten Kammer. All rights reserved.
//

#import "GLLMeshSettings.h"

#import "GLLItem.h"
#import "GLLMesh.h"
#import "GLLModel.h"

@implementation GLLMeshSettings

@dynamic cullFaceMode;
@dynamic isVisible;
@dynamic item;

@dynamic mesh;
@dynamic meshIndex;
@dynamic displayName;

- (NSUInteger)meshIndex
{
	return [self.item.meshSettings indexOfObject:self];
}

- (GLLMesh *)mesh
{
	return self.item.model.meshes[self.meshIndex];
}

- (NSString *)displayName
{
	return self.mesh.name;
}

#pragma mark - Source list item

- (BOOL)isSourceListHeader
{
	return NO;
}
- (NSString *)sourceListDisplayName
{
	return self.mesh.name;
}
- (BOOL)hasChildrenInSourceList
{
	return NO;
}
- (NSUInteger)numberOfChildrenInSourceList
{
	return 0;
}
- (id)childInSourceListAtIndex:(NSUInteger)index;
{
	return nil;
}

@end
