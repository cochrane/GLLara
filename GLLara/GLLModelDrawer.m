//
//  GLLModelDrawer.m
//  GLLara
//
//  Created by Torsten Kammer on 03.09.12.
//  Copyright (c) 2012 Torsten Kammer. All rights reserved.
//

#import "GLLModelDrawer.h"

#import "GLLMesh.h"
#import "GLLMeshDrawer.h"
#import "GLLModel.h"

@implementation GLLModelDrawer

- (id)initWithModel:(GLLModel *)model resourceManager:(GLLResourceManager *)resourceManager;
{
	if (!(self = [super init])) return nil;
	
	_model = model;
	_resourceManager = resourceManager;
	
	NSMutableArray *mutableNormalMeshDrawers = [[NSMutableArray alloc] init];
	NSMutableArray *mutableAlphaMeshDrawers = [[NSMutableArray alloc] init];
	for (GLLMesh *mesh in model.meshes)
	{
		// Ignore objects that can't be rendered.
		if (!mesh.shader)
			continue;
		
		if (mesh.isAlphaPiece)
			[mutableAlphaMeshDrawers addObject:[[GLLMeshDrawer alloc] initWithMesh:mesh resourceManager:resourceManager]];
		else
			[mutableNormalMeshDrawers addObject:[[GLLMeshDrawer alloc] initWithMesh:mesh resourceManager:resourceManager]];
	}
	_normalMeshDrawers = [mutableNormalMeshDrawers copy];
	_alphaMeshDrawers = [mutableAlphaMeshDrawers copy];
	
	return self;
}

- (void)unload;
{
	for (GLLMeshDrawer *drawer in self.normalMeshDrawers)
		[drawer unload];
	for (GLLMeshDrawer *drawer in self.alphaMeshDrawers)
		[drawer unload];
	
	_normalMeshDrawers = nil;
	_alphaMeshDrawers = nil;
}

@end
