//
//  GLLModelMeshObj.m
//  GLLara
//
//  Created by Torsten Kammer on 12.09.12.
//  Copyright (c) 2012 Torsten Kammer. All rights reserved.
//

#import "GLLModelMeshObj.h"

@implementation GLLModelMeshObj

- (id)initWithObjFile:(GLLObjFile *)file range:(const GLLObjFile::MaterialRange &)range;
{
	if (!(self = [super init])) return nil;
	
	// Procedure: Go through the indices in the range. For each index, load the vertex data from the file and put it in the vertex buffer here. Adjust the index, too.
	
	std::map<unsigned, uint32_t> globalToLocalVertices;
	NSMutableData *vertices = [NSMutableData data];
	NSMutableData *elements = [[NSMutableData alloc] initWithCapacity:sizeof(uint32_t) * (range.end - range.start)];
	
	for (unsigned i = range.start; i < range.end; i++)
	{
		uint32_t index = 0;
		auto localIndexIter = globalToLocalVertices.find(i);
		if (localIndexIter == globalToLocalVertices.end())
		{
			// Add adjusted element
			index = (uint32_t) globalToLocalVertices.size();
			globalToLocalVertices[i] = index;
			
			// Add vertex
			const GLLObjFile::VertexData &vertex = file->getVertexData()[i];
			
			[vertices appendBytes:vertex.vert length:sizeof(float [3])];
			[vertices appendBytes:vertex.norm length:sizeof(float [3])];
			[vertices appendBytes:vertex.color length:sizeof(uint8_t [4])];
			[vertices appendBytes:vertex.tex length:sizeof(float [2])];
			
			float zero[4] = { 0, 0, 0, 0 };
			[vertices appendBytes:&zero length:sizeof(zero)];
			
			// No bone weights or indices here; OBJs use special shaders that don't use them.
		}
		
		// Add to element buffer
		[elements appendBytes:&index length:sizeof(index)];
	}
	
	// Calculate tangents
	[self calculateTangents:vertices];
	
	// Set up other attributes
	self.vertexData = [vertices copy];
	self.elementData = [elements copy];
	self.countOfVertices = globalToLocalVertices.size();
	self.countOfElements = range.end - range.start;
	
	// Setup material
//#error Setup material
	
	return self;
}

- (BOOL)hasBoneWeights
{
	return NO; // OBJ files don't use them. They do use one bone matrix, for the model position, but that's it.
}

@end
