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
#import "GLLMeshSettings.h"
#import "GLLModelDrawer.h"
#import "GLLSceneDrawer.h"
#import "GLLResourceManager.h"
#import "GLLTransformedMeshDrawer.h"
#import "simd_types.h"

@interface GLLItemDrawer ()
{
	NSArray *alphaDrawers;
	NSArray *solidDrawers;
}

@end

@implementation GLLItemDrawer

- (id)initWithItem:(GLLItem *)item sceneDrawer:(GLLSceneDrawer *)sceneDrawer;
{
	if (!(self = [super init])) return nil;
	
	_item = item;
	_sceneDrawer = sceneDrawer;
	
	GLLModelDrawer *modelDrawer = [sceneDrawer.resourceManager drawerForModel:item.model];
	
	NSMutableArray *mutableAlphaDrawers = [[NSMutableArray alloc] initWithCapacity:modelDrawer.alphaMeshDrawers.count];
	for (GLLMeshDrawer *drawer in modelDrawer.alphaMeshDrawers)
		[mutableAlphaDrawers addObject:[[GLLTransformedMeshDrawer alloc] initWithDrawer:drawer settings:[item settingsForMesh:drawer.mesh]]];
	alphaDrawers = [mutableAlphaDrawers copy];
	
	NSMutableArray *mutableSolidDrawers = [[NSMutableArray alloc] initWithCapacity:modelDrawer.solidMeshDrawers.count];
	for (GLLMeshDrawer *drawer in modelDrawer.solidMeshDrawers)
		[mutableSolidDrawers addObject:[[GLLTransformedMeshDrawer alloc] initWithDrawer:drawer settings:[item settingsForMesh:drawer.mesh]]];
	solidDrawers = [mutableSolidDrawers copy];
	
	return self;
}

- (void)drawSolid;
{
	mat_float16 transforms[60];
	for (GLLTransformedMeshDrawer *drawer in solidDrawers)
	{
		[_item getTransforms:transforms maxCount:60 forMesh:drawer.settings.mesh];
		[drawer drawWithTransforms:transforms];
	}
}
- (void)drawAlpha;
{
	mat_float16 transforms[60];
	for (GLLTransformedMeshDrawer *drawer in alphaDrawers)
	{
		[_item getTransforms:transforms maxCount:60 forMesh:drawer.settings.mesh];
		[drawer drawWithTransforms:transforms];
	}
}

@end
