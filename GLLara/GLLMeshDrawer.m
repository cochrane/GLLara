//
//  GLLMeshDrawer.m
//  GLLara
//
//  Created by Torsten Kammer on 01.09.12.
//  Copyright (c) 2012 Torsten Kammer. All rights reserved.
//

#import "GLLMeshDrawer.h"

#import <OpenGL/gl3.h>

#import "NSArray+Map.h"
#import "GLLModelMesh.h"
#import "GLLModelProgram.h"
#import "GLLVertexFormat.h"
#import "GLLUniformBlockBindings.h"
#import "GLLResourceManager.h"
#import "GLLTexture.h"
#import "LionSubscripting.h"

@interface GLLMeshDrawer ()
{
	GLuint vertexArray;
	GLsizei elementsCount;
}

@end

@implementation GLLMeshDrawer

- (id)initWithMesh:(GLLModelMesh *)mesh resourceManager:(GLLResourceManager *)resourceManager error:(NSError *__autoreleasing*)error;
{
	if (!(self = [super init])) return nil;
	
	_modelMesh = mesh;
			
	// Create the element and vertex buffers, and spend a lot of time setting up the vertex attribute arrays and pointers.
	glGenVertexArrays(1, &vertexArray);
	glBindVertexArray(vertexArray);
	
	GLuint buffers[2];
	glGenBuffers(2, buffers);
	
	glBindBuffer(GL_ARRAY_BUFFER, buffers[0]);
	glBufferData(GL_ARRAY_BUFFER, mesh.vertexData.length, mesh.vertexData.bytes, GL_STATIC_DRAW);
	
	glEnableVertexAttribArray(GLLVertexAttribPosition);
	glVertexAttribPointer(GLLVertexAttribPosition, 3, GL_FLOAT, GL_FALSE, (GLsizei) mesh.stride, (GLvoid *) mesh.offsetForPosition);
	
	glEnableVertexAttribArray(GLLVertexAttribNormal);
	glVertexAttribPointer(GLLVertexAttribNormal, 3, GL_FLOAT, GL_FALSE, (GLsizei) mesh.stride, (GLvoid *) mesh.offsetForNormal);
	
	glEnableVertexAttribArray(GLLVertexAttribColor);
	glVertexAttribPointer(GLLVertexAttribColor, 4, GL_UNSIGNED_BYTE, GL_TRUE, (GLsizei) mesh.stride, (GLvoid *) mesh.offsetForColor);
	
	if (mesh.hasBoneWeights)
	{
		glEnableVertexAttribArray(GLLVertexAttribBoneIndices);
		glVertexAttribIPointer(GLLVertexAttribBoneIndices, 4, GL_UNSIGNED_SHORT, (GLsizei) mesh.stride, (GLvoid *) mesh.offsetForBoneIndices);
		
		glEnableVertexAttribArray(GLLVertexAttribBoneWeights);
		glVertexAttribPointer(GLLVertexAttribBoneWeights, 4, GL_FLOAT, GL_FALSE, (GLsizei) mesh.stride, (GLvoid *) mesh.offsetForBoneWeights);
	}
	
	for (GLuint i = 0; i < mesh.countOfUVLayers; i++)
	{
		glEnableVertexAttribArray(GLLVertexAttribTexCoord0 + 2*i);
		glVertexAttribPointer(GLLVertexAttribTexCoord0 + 2*i, 2, GL_FLOAT, GL_FALSE, (GLsizei) mesh.stride, (GLvoid *) [mesh offsetForTexCoordLayer:i]);
		
		if (mesh.hasTangents)
		{
			glEnableVertexAttribArray(GLLVertexAttribTangent0 + 2*i);
			glVertexAttribPointer(GLLVertexAttribTangent0 + 2*i, 4, GL_FLOAT, GL_FALSE, (GLsizei) mesh.stride, (GLvoid *) [mesh offsetForTangentLayer:i]);
		}
	}
	
	glBindBuffer(GL_ELEMENT_ARRAY_BUFFER, buffers[1]);
	glBufferData(GL_ELEMENT_ARRAY_BUFFER, mesh.elementData.length, mesh.elementData.bytes, GL_STATIC_DRAW);
	
	elementsCount = (GLsizei) mesh.countOfElements;
	
	glBindVertexArray(0);
	glDeleteBuffers(2, buffers);
	
	return self;
}

- (void)draw;
{
	// Load and draw the vertices
	glBindVertexArray(vertexArray);
	glDrawElements(GL_TRIANGLES, elementsCount, GL_UNSIGNED_INT, NULL);
}

- (void)unload
{
	glDeleteVertexArrays(1, &vertexArray);
	vertexArray = 0;
	elementsCount = 0;
}

- (void)dealloc
{
	NSAssert(vertexArray == 0 && elementsCount == 0, @"Did not call unload before calling dealloc!");
}

@end
