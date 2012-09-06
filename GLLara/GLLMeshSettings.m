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

@implementation GLLMeshSettings

- (id)initWithItem:(GLLItem *)item mesh:(GLLMesh *)mesh;
{
	if (!(self = [super init])) return nil;
	
	_item = item;
	_mesh = mesh;
	_isVisible = YES;
	
	return self;
}

- (NSString *)displayName
{
	return self.mesh.name;
}

- (void)setIsVisible:(BOOL)isVisible
{
	_isVisible = isVisible;
	[self.item changedPosition];
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
