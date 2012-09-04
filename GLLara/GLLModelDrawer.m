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
	
	NSMutableArray *mutableMeshDrawers = [[NSMutableArray alloc] initWithCapacity:model.meshes.count];
	for (GLLMesh *mesh in model.meshes)
		[mutableMeshDrawers addObject:[[GLLMeshDrawer alloc] initWithMesh:mesh resourceManager:resourceManager]];
	_meshDrawers = [mutableMeshDrawers copy];
	
	return self;
}

@end
