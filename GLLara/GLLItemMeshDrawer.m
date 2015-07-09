//
//  GLLItemMeshDrawer.m
//  GLLara
//
//  Created by Torsten Kammer on 06.09.12.
//  Copyright (c) 2012 Torsten Kammer. All rights reserved.
//

#import "GLLItemMeshDrawer.h"

#import <OpenGL/gl3.h>

#import "GLLItemDrawer.h"
#import "GLLItemMeshTexture.h"
#import "GLLMeshDrawer.h"
#import "GLLModelMesh.h"
#import "GLLItemMesh.h"
#import "GLLModelProgram.h"
#import "GLLRenderParameter.h"
#import "GLLResourceManager.h"
#import "GLLShaderDescription.h"
#import "GLLTexture.h"
#import "GLLUniformBlockBindings.h"
#import "NSArray+Map.h"

@interface GLLItemMeshDrawer ()
{
	GLuint renderParametersBuffer;
	BOOL needsParameterBufferUpdate;
	NSSet *renderParameters;
	NSSet *textureAssignments;
	NSArray *textures;
	BOOL needsTextureUpdate;
	BOOL needsProgramUpdate;
}
- (void)_updateParameterBuffer;
- (BOOL)_updateTexturesError:(NSError *__autoreleasing*)error;
- (BOOL)_updateShaderError:(NSError *__autoreleasing*)error;

@end

@implementation GLLItemMeshDrawer

- (id)initWithItemDrawer:(GLLItemDrawer *)itemDrawer meshDrawer:(GLLMeshDrawer *)meshDrawer itemMesh:(GLLItemMesh *)itemMesh error:(NSError *__autoreleasing*)error;
{
	if (!(self = [super init])) return nil;
	
	NSAssert(itemDrawer != nil && meshDrawer != nil && itemMesh != nil, @"None of this can be nil");
	
	_itemDrawer = itemDrawer;
	_meshDrawer = meshDrawer;
	_itemMesh = itemMesh;
	
	[_itemMesh addObserver:self forKeyPath:@"shaderName" options:NSKeyValueObservingOptionNew context:NULL];
	if (![self _updateShaderError:error])
		return nil;
	
	glGenBuffers(1, &renderParametersBuffer);
	needsParameterBufferUpdate = YES;
	
	[_itemMesh addObserver:self forKeyPath:@"textures" options:NSKeyValueObservingOptionInitial | NSKeyValueObservingOptionNew | NSKeyValueObservingOptionOld context:NULL];
	[_itemMesh addObserver:self forKeyPath:@"renderParameters" options:NSKeyValueObservingOptionInitial | NSKeyValueObservingOptionNew | NSKeyValueObservingOptionOld context:NULL];
	
	if (![self _updateTexturesError:error])
	{
		[self unload];
		return nil;
	}
		
	return self;
}

- (void)dealloc
{
	NSAssert(renderParametersBuffer == 0, @"Did not call unload before calling dealloc!");
	
	// Unregister observers
	for (GLLRenderParameter *param in renderParameters)
		[param removeObserver:self forKeyPath:@"uniformValue"];
	[_itemMesh removeObserver:self forKeyPath:@"renderParameters"];
	
	for (GLLItemMeshTexture *texture in textureAssignments)
		[texture removeObserver:self forKeyPath:@"textureURL"];
	[_itemMesh removeObserver:self forKeyPath:@"textures"];
	
	[_itemMesh removeObserver:self forKeyPath:@"shaderName"];
}

- (void)observeValueForKeyPath:(NSString *)keyPath ofObject:(id)object change:(NSDictionary *)change context:(void *)context
{
	if ([keyPath isEqual:@"renderParameters"])
	{
		for (GLLRenderParameter *param in renderParameters)
			[param removeObserver:self forKeyPath:@"uniformValue"];
		
		renderParameters = [_itemMesh.renderParameters copy];
		for (GLLRenderParameter *param in renderParameters)
			[param addObserver:self forKeyPath:@"uniformValue" options:NSKeyValueObservingOptionNew context:NULL];

		needsParameterBufferUpdate = YES;
	}
	else if ([keyPath isEqual:@"uniformValue"])
	{
		needsParameterBufferUpdate = YES;
		self.itemDrawer.needsRedraw = YES;
	}
	else if ([keyPath isEqual:@"textures"])
	{
		for (GLLItemMeshTexture *texture in textureAssignments)
			[texture removeObserver:self forKeyPath:@"textureURL"];
		
		textureAssignments = [_itemMesh.textures copy];
		for (GLLItemMeshTexture *texture in textureAssignments)
			[texture addObserver:self forKeyPath:@"textureURL" options:NSKeyValueObservingOptionNew context:NULL];
		needsTextureUpdate = YES;
	}
	else if ([keyPath isEqual:@"textureURL"])
	{
		needsTextureUpdate = YES;
		self.itemDrawer.needsRedraw = YES;
	}
	else if ([keyPath isEqual:@"shaderName"])
	{
		needsTextureUpdate = YES;
		needsProgramUpdate = YES;
		self.itemDrawer.needsRedraw = YES;
	}
	else
		[super observeValueForKeyPath:keyPath ofObject:object change:change context:context];
}

- (void)drawWithState:(GLLDrawState *)state;
{
	if (!self.itemMesh.isVisible)
		return;
	if (!self.program)
		return;
	if (needsProgramUpdate)
		[self _updateShaderError:NULL];
	if (needsParameterBufferUpdate)
		[self _updateParameterBuffer];
	if (needsTextureUpdate)
		[self _updateTexturesError:NULL];
	
	if (state->cullFaceMode != self.itemMesh.cullFaceMode)
	{
		// Set cull mode
		switch (self.itemMesh.cullFaceMode)
		{
			case GLLCullCounterClockWise:
				if (state->cullFaceMode == GLLCullNone) glEnable(GL_CULL_FACE);
				glFrontFace(GL_CW);
				break;
				
			case GLLCullClockWise:
				if (state->cullFaceMode == GLLCullNone) glEnable(GL_CULL_FACE);
				glFrontFace(GL_CCW);
				break;
				
			case GLLCullNone:
				glDisable(GL_CULL_FACE);
				
			default:
				break;
		}
		state->cullFaceMode = self.itemMesh.cullFaceMode;
	}
	
	// If there are render parameters, apply them
	if (renderParametersBuffer != 0)
		glBindBufferBase(GL_UNIFORM_BUFFER, GLLUniformBlockBindingRenderParameters, renderParametersBuffer);
	
	for (NSUInteger i = 0; i < textures.count; i++)
	{
		glActiveTexture(GL_TEXTURE0 + (GLenum) i);
		glBindTexture(GL_TEXTURE_2D, [textures[i] textureID]);
	}
	
	// Use this program, with the correct transformation.
	if (state->activeProgram != self.program.programID)
	{
		glUseProgram(self.program.programID);
		state->activeProgram = self.program.programID;
	}
	
	[self.meshDrawer draw];
}

- (void)unload
{
	glDeleteBuffers(1, &renderParametersBuffer);
	renderParametersBuffer = 0;
	
	renderParameters = nil;
}

#pragma mark - Private methods

- (void)_updateParameterBuffer;
{
	GLint bufferLength;
	
	if (!_program)
		return;
	
	if (self.program.renderParametersUniformBlockIndex == GL_INVALID_INDEX)
		return;
	
	glGetActiveUniformBlockiv(self.program.programID, self.program.renderParametersUniformBlockIndex, GL_UNIFORM_BLOCK_DATA_SIZE, &bufferLength);
	void *data = calloc(1, bufferLength);
	
	for (GLLRenderParameter *parameter in self.itemMesh.renderParameters)
	{
		NSString *fullName = [@"RenderParameters." stringByAppendingString:parameter.name];
		GLuint uniformIndex;
		glGetUniformIndices(self.program.programID, 1, (const GLchar *[]) { fullName.UTF8String }, &uniformIndex);
		if (uniformIndex == GL_INVALID_INDEX) continue;
		
		GLint byteOffset;
		glGetActiveUniformsiv(self.program.programID, 1, &uniformIndex, GL_UNIFORM_OFFSET, &byteOffset);
		
		[parameter.uniformValue getBytes:&data[byteOffset] length:bufferLength - byteOffset];
	}
	
	glBindBufferBase(GL_UNIFORM_BUFFER, GLLUniformBlockBindingRenderParameters, renderParametersBuffer);
	glBufferData(GL_UNIFORM_BUFFER, bufferLength, data, GL_STREAM_DRAW);
	
	free(data);

	needsParameterBufferUpdate = NO;
}

- (BOOL)_updateTexturesError:(NSError *__autoreleasing*)error;
{
	needsTextureUpdate = NO;
	
	if (!_program)
		return YES;
	
	textures = [self.itemMesh.shader.textureUniformNames map:^(NSString *identifier){
		GLLItemMeshTexture *textureAssignment = [self.itemMesh textureWithIdentifier:identifier];
		return [[GLLResourceManager sharedResourceManager] textureForURL:textureAssignment.textureURL error:error];
	}];
	if (textures.count < self.itemMesh.shader.textureUniformNames.count)
		return NO;
	else
		return YES;
}

- (BOOL)_updateShaderError:(NSError *__autoreleasing*)error;
{
	needsParameterBufferUpdate = YES;
	needsTextureUpdate = YES;
	needsProgramUpdate = NO;
	
	if (self.itemMesh.shaderName == nil)
	{
		// Allow empty programs for objects
		// that don't have a shader.
		_program = nil;
		return YES;
	}
	
	_program = [[GLLResourceManager sharedResourceManager] programForDescriptor:self.itemMesh.shader error:error];
	if (!self.program)
		return NO;
	
	return YES;
}

@end
