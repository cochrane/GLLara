//
//  GLLModelDrawer.m
//  GLLara
//
//  Created by Torsten Kammer on 03.09.12.
//  Copyright (c) 2012 Torsten Kammer. All rights reserved.
//

#import "GLLModelDrawer.h"

#import "GLLMeshDrawer.h"
#import "GLLModel.h"
#import "GLLModelMesh.h"

@implementation GLLModelDrawer

- (id)initWithModel:(GLLModel *)model resourceManager:(GLLResourceManager *)resourceManager error:(NSError *__autoreleasing *)error;
{
	if (!(self = [super init])) return nil;
	
	_model = model;
	_resourceManager = resourceManager;
	
	NSMutableArray *mutableSolidMeshDrawers = [[NSMutableArray alloc] init];
	NSMutableArray *mutableAlphaMeshDrawers = [[NSMutableArray alloc] init];
	for (GLLModelMesh *mesh in model.meshes)
	{
		// Ignore objects that can't be rendered.
		if (!mesh.shader)
			continue;
		
		GLLMeshDrawer *drawer = [[GLLMeshDrawer alloc] initWithMesh:mesh resourceManager:resourceManager error:error];
		if (!drawer)
		{
			for (GLLMeshDrawer *drawer in mutableSolidMeshDrawers)
				[drawer unload];
			for (GLLMeshDrawer *drawer in mutableAlphaMeshDrawers)
				[drawer unload];
			[self unload];
			return nil;
		}
		
		if (mesh.usesAlphaBlending)
			[mutableAlphaMeshDrawers addObject:drawer];
		else
			[mutableSolidMeshDrawers addObject:drawer];
	}
	_solidMeshDrawers = [mutableSolidMeshDrawers copy];
	_alphaMeshDrawers = [mutableAlphaMeshDrawers copy];
	
	return self;
}

- (void)unload;
{
	for (GLLMeshDrawer *drawer in self.solidMeshDrawers)
		[drawer unload];
	for (GLLMeshDrawer *drawer in self.alphaMeshDrawers)
		[drawer unload];
	
	_solidMeshDrawers = nil;
	_alphaMeshDrawers = nil;
}

@end
