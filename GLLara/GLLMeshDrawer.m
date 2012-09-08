//
//  GLLMeshDrawer.m
//  GLLara
//
//  Created by Torsten Kammer on 01.09.12.
//  Copyright (c) 2012 Torsten Kammer. All rights reserved.
//

#import "GLLMeshDrawer.h"

#import <OpenGL/gl3.h>

#import "GLLMesh.h"
#import "GLLProgram.h"
#import "GLLVertexFormat.h"
#import "GLLUniformBlockBindings.h"
#import "GLLResourceManager.h"
#import "GLLTexture.h"

@interface GLLMeshDrawer ()
{
	GLuint vertexArray;
	GLsizei elementsCount;
	
	GLuint renderParametersBuffer;
}

@end

@implementation GLLMeshDrawer

- (id)initWithMesh:(GLLMesh *)mesh resourceManager:(GLLResourceManager *)resourceManager error:(NSError *__autoreleasing*)error;
{
	if (!(self = [super init])) return nil;
	
	_mesh = mesh;
	
	// Set up shader
	_program = [resourceManager programForDescriptor:mesh.shader error:error];
	if (!_program) return nil;
	
	// Set up textures
	NSMutableArray *textures = [[NSMutableArray alloc] initWithCapacity:mesh.textures.count];
	for (NSDictionary *textureDescription in mesh.textures)
	{
		GLLTexture *texture = [resourceManager textureForName:textureDescription[@"name"] baseURL:mesh.baseURL error:error];
		if (!texture) return nil;
		[textures addObject:texture];
		
	}
	_textures = [textures copy];
	
	// If there are render parameters to be set, create a uniform buffer for them and set their values from the mesh.
	if (_program.renderParametersUniformBlockIndex != GL_INVALID_INDEX)
	{
		GLint bufferLength;
		glGetActiveUniformBlockiv(_program.programID, _program.renderParametersUniformBlockIndex, GL_UNIFORM_BLOCK_DATA_SIZE, &bufferLength);
		void *data = malloc(bufferLength);
		
		for (NSString *uniformName in mesh.renderParameters)
		{
			NSString *fullName = [@"RenderParameters." stringByAppendingString:uniformName];
			GLuint uniformIndex;
			glGetUniformIndices(_program.programID, 1, (const GLchar *[]) { fullName.UTF8String }, &uniformIndex);
			if (uniformIndex == GL_INVALID_INDEX) continue;
			
			GLint byteOffset;
			glGetActiveUniformsiv(_program.programID, 1, &uniformIndex, GL_UNIFORM_OFFSET, &byteOffset);
			
			*((float *) &data[byteOffset]) = [mesh.renderParameters[uniformName] floatValue];
		}
		
		glGenBuffers(1, &renderParametersBuffer);
		glBindBuffer(GL_UNIFORM_BUFFER, renderParametersBuffer);
		glBufferData(GL_UNIFORM_BUFFER, bufferLength, data, GL_STATIC_DRAW);
		
		free(data);
	}
	
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
		
		glEnableVertexAttribArray(GLLVertexAttribTangent0 + 2*i);
		glVertexAttribPointer(GLLVertexAttribTangent0 + 2*i, 4, GL_FLOAT, GL_FALSE, (GLsizei) mesh.stride, (GLvoid *) [mesh offsetForTangentLayer:i]);
	}
	
	glBindBuffer(GL_ELEMENT_ARRAY_BUFFER, buffers[1]);
	glBufferData(GL_ELEMENT_ARRAY_BUFFER, mesh.elementData.length, mesh.elementData.bytes, GL_STATIC_DRAW);
	
	elementsCount = (GLsizei) mesh.countOfElements;
	
	glBindVertexArray(0);
	glDeleteBuffers(2, buffers);
	
	return self;
}

- (void)drawWithTransforms:(const mat_float16 *)transforms;
{
	// Use this program, with the correct transformation.
	glUseProgram(self.program.programID);
	glUniformMatrix4fv(self.program.boneMatricesUniformLocation, (GLsizei) self.mesh.boneIndices.count, GL_FALSE, (const GLfloat *) transforms);
	
	// If there are render parameters, apply them
	if (renderParametersBuffer != 0)
		glBindBufferBase(GL_UNIFORM_BUFFER, GLLUniformBlockBindingRenderParameters, renderParametersBuffer);

	// And don't forget the textures
	for (GLuint i = 0; i < self.textures.count; i++)
	{
		glActiveTexture(GL_TEXTURE0 + i);
		glBindTexture(GL_TEXTURE_2D, [self.textures[i] textureID]);
	}
	
	// Load and draw the vertices
	glBindVertexArray(vertexArray);
	glDrawElements(GL_TRIANGLES, elementsCount, GL_UNSIGNED_INT, NULL);
}

- (void)unload
{
	glDeleteVertexArrays(1, &vertexArray);
	glDeleteBuffers(1, &renderParametersBuffer);
	vertexArray = 0;
	elementsCount = 0;
	renderParametersBuffer = 0;
}

- (void)dealloc
{
	NSAssert(vertexArray == 0 && elementsCount == 0 && renderParametersBuffer == 0, @"Did not call unload before calling dealloc!");
}

@end
