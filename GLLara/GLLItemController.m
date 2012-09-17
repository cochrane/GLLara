//
//  GLLItemController.m
//  GLLara
//
//  Created by Torsten Kammer on 17.09.12.
//  Copyright (c) 2012 Torsten Kammer. All rights reserved.
//

#import "GLLItemController.h"

#import "GLLItem.h"
#import "GLLSourceListMarker.h"

@interface GLLItemController ()
{
	GLLSourceListMarker *bonesMarker;
	GLLSourceListMarker *meshesMarker;
}

@end

@implementation GLLItemController

+ (NSSet *)keyPathsForValuesAffectingSourceListDisplayName
{
	return [NSSet setWithObject:@"item.displayName"];
}

- (id)initWithItem:(GLLItem *)item;
{
	if (!(self = [super init])) return nil;
	
	self.item = item;
		
	return self;
}

- (void)setSourceListDisplayName:(NSString *)displayName
{
	self.item.displayName = displayName;
}

#pragma mark - Source List Item

- (BOOL)isSourceListHeader
{
	return NO;
}
- (NSString *)sourceListDisplayName
{
	return self.item.displayName;
}
- (BOOL)isLeafInSourceList
{
	return NO;
}
- (NSUInteger)countOfSourceListChildren
{
	return 2;
}
- (id)objectInSourceListChildrenAtIndex:(NSUInteger)index;
{
	if (index == 0)
	{
		if (!meshesMarker)
		{
			meshesMarker = [[GLLSourceListMarker alloc] initWithObject:self childrenKeyPath:@"item.meshes"];
			meshesMarker.sourceListDisplayName = NSLocalizedString(@"Meshes", @"source list: meshes subheader");
		}
		return meshesMarker;
	}
	else if (index == 1)
	{
		if (!bonesMarker)
		{
			bonesMarker = [[GLLSourceListMarker alloc] initWithObject:self childrenKeyPath:@"item.rootBones"];
			bonesMarker.sourceListDisplayName = NSLocalizedString(@"Bones", @"source list: bones subheader");
		}
		return bonesMarker;
	}
	else return nil;
}

@end
