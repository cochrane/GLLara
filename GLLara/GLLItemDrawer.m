//
//  GLLItemDrawer.m
//  GLLara
//
//  Created by Torsten Kammer on 03.09.12.
//  Copyright (c) 2012 Torsten Kammer. All rights reserved.
//

#import "GLLItemDrawer.h"

#import "GLLItem.h"
#import "GLLMeshDrawer.h"
#import "simd_types.h"

@interface GLLItemDrawer ()
{
	NSArray *normalMeshes;
	NSArray *alphaMeshes;
}

@end

@implementation GLLItemDrawer

- (id)initWithItem:(GLLItem *)item sceneDrawer:(GLLSceneDrawer *)sceneDrawer;
{
	if (!(self = [super init])) return nil;
	
	_item = item;
	_sceneDrawer = sceneDrawer;
	
	return self;
}

- (void)drawNormal;
{
	mat_float16 transforms[60];
	for (GLLMeshDrawer *drawer in normalMeshes)
	{
		[_item getTransforms:transforms maxCount:60 forMesh:drawer.mesh];
		[drawer drawWithTransforms:transforms];
	}
}
- (void)drawAlpha;
{
	mat_float16 transforms[60];
	for (GLLMeshDrawer *drawer in alphaMeshes)
	{
		[_item getTransforms:transforms maxCount:60 forMesh:drawer.mesh];
		[drawer drawWithTransforms:transforms];
	}
}

@end
