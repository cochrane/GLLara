//
//  GLLItemDrawer.m
//  GLLara
//
//  Created by Torsten Kammer on 03.09.12.
//  Copyright (c) 2012 Torsten Kammer. All rights reserved.
//

#import "GLLItemDrawer.h"

#import "GLLItem.h"
#import "GLLModelDrawer.h"
#import "GLLMeshDrawer.h"
#import "GLLSceneDrawer.h"
#import "GLLResourceManager.h"
#import "simd_types.h"

@interface GLLItemDrawer ()
{
	GLLModelDrawer *modelDrawer;
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
	if (!modelDrawer) modelDrawer = [_sceneDrawer.resourceManager drawerForModel:_item.model];

	mat_float16 transforms[60];
	for (GLLMeshDrawer *drawer in modelDrawer.normalMeshDrawers)
	{
		[_item getTransforms:transforms maxCount:60 forMesh:drawer.mesh];
		[drawer drawWithTransforms:transforms];
	}
}
- (void)drawAlpha;
{
	if (!modelDrawer) modelDrawer = [_sceneDrawer.resourceManager drawerForModel:_item.model];
	
	mat_float16 transforms[60];
	for (GLLMeshDrawer *drawer in modelDrawer.alphaMeshDrawers)
	{
		[_item getTransforms:transforms maxCount:60 forMesh:drawer.mesh];
		[drawer drawWithTransforms:transforms];
	}
}

@end
