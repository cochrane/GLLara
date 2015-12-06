//
//  GLLModelDrawer.m
//  GLLara
//
//  Created by Torsten Kammer on 03.09.12.
//  Copyright (c) 2012 Torsten Kammer. All rights reserved.
//

#import "GLLModelDrawer.h"

#import "GLLMeshDrawData.h"
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
	
	NSMutableArray *mutableSolidMeshDatas = [[NSMutableArray alloc] init];
	NSMutableArray *mutableAlphaMeshDatas = [[NSMutableArray alloc] init];
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
        
        GLLMeshDrawData *drawData = [[GLLMeshDrawData alloc] initWithMesh:mesh vertexArray:array resourceManager:resourceManager error:error];
		if (!drawData)
		{
			for (GLLMeshDrawData *drawer in mutableSolidMeshDatas)
				[drawer unload];
			for (GLLMeshDrawData *drawer in mutableAlphaMeshDatas)
				[drawer unload];
			[self unload];
			return nil;
		}
		
		if (mesh.usesAlphaBlending)
			[mutableAlphaMeshDatas addObject:drawData];
		else
			[mutableSolidMeshDatas addObject:drawData];
	}
    
	_solidMeshDatas = [mutableSolidMeshDatas copy];
	_alphaMeshDatas = [mutableAlphaMeshDatas copy];
    _vertexArrays = [[mutableVertexArrays allValues] copy];
    
    for (GLLVertexArray *array in _vertexArrays) {
        [array upload];
    }
	
	return self;
}

- (void)unload;
{
	[self.solidMeshDatas makeObjectsPerformSelector:@selector(unload)];
    [self.alphaMeshDatas makeObjectsPerformSelector:@selector(unload)];
    [self.vertexArrays makeObjectsPerformSelector:@selector(unload)];
	
	_solidMeshDatas = nil;
	_alphaMeshDatas = nil;
    _vertexArrays = nil;
}

@end
