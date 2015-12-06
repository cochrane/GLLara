//
//  GLLModelDrawData.m
//  GLLara
//
//  Created by Torsten Kammer on 03.09.12.
//  Copyright (c) 2012 Torsten Kammer. All rights reserved.
//

#import "GLLModelDrawData.h"

#import "GLLMeshDrawData.h"
#import "GLLModel.h"
#import "GLLModelMesh.h"
#import "GLLVertexArray.h"
#import "GLLVertexFormat.h"

@interface GLLModelDrawData ()

@property (nonatomic, retain, readonly) NSArray *vertexArrays;

@end

@implementation GLLModelDrawData

- (id)initWithModel:(GLLModel *)model resourceManager:(GLLResourceManager *)resourceManager error:(NSError *__autoreleasing *)error;
{
	if (!(self = [super init])) return nil;
	
	_model = model;
	_resourceManager = resourceManager;
	
	NSMutableArray *mutableMeshDatas = [[NSMutableArray alloc] init];
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
			for (GLLMeshDrawData *drawer in mutableMeshDatas)
				[drawer unload];
			[self unload];
			return nil;
		}
		
        [mutableMeshDatas addObject:drawData];
	}
    
	_meshDatas = [mutableMeshDatas copy];
    _vertexArrays = [[mutableVertexArrays allValues] copy];
    
    for (GLLVertexArray *array in _vertexArrays) {
        [array upload];
    }
	
	return self;
}

- (void)unload;
{
	[self.meshDatas makeObjectsPerformSelector:@selector(unload)];
    [self.vertexArrays makeObjectsPerformSelector:@selector(unload)];
	
	_meshDatas = nil;
    _vertexArrays = nil;
}

@end
