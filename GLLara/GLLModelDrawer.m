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
#import "GLLVertexArray.h"
#import "GLLVertexFormat.h"

@interface GLLModelDrawer ()

@property (nonatomic, retain, readonly) NSArray *vertexArrays;

@end

@implementation GLLModelDrawer

- (id)initWithModel:(GLLModel *)model resourceManager:(GLLResourceManager *)resourceManager error:(NSError *__autoreleasing *)error;
{
	if (!(self = [super init])) return nil;
	
	_model = model;
	_resourceManager = resourceManager;
	
	NSMutableArray *mutableSolidMeshDrawers = [[NSMutableArray alloc] init];
	NSMutableArray *mutableAlphaMeshDrawers = [[NSMutableArray alloc] init];
    NSMutableDictionary *mutableVertexArrays = [[NSMutableDictionary alloc] init];
	for (GLLModelMesh *mesh in model.meshes)
	{
		// Ignore objects that can't be rendered.
		if (!mesh.shader)
			continue;
		
        GLLVertexArray *array = mutableVertexArrays[mesh.vertexFormat];
        if (!array) {
            array = [[GLLVertexArray alloc] initWithFormat:mesh.vertexFormat];
            mutableVertexArrays[mesh.vertexFormat] = array;
        }
        
        GLLMeshDrawer *drawer = [[GLLMeshDrawer alloc] initWithMesh:mesh vertexArray:array resourceManager:resourceManager error:error];
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
    _vertexArrays = [[mutableVertexArrays allValues] copy];
    
    for (GLLVertexArray *array in _vertexArrays) {
        [array upload];
    }
	
	return self;
}

- (void)unload;
{
	[self.solidMeshDrawers makeObjectsPerformSelector:@selector(unload)];
    [self.alphaMeshDrawers makeObjectsPerformSelector:@selector(unload)];
    [self.vertexArrays makeObjectsPerformSelector:@selector(unload)];
	
	_solidMeshDrawers = nil;
	_alphaMeshDrawers = nil;
    _vertexArrays = nil;
}

@end
