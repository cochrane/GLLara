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
#import "GLLRenderParameterDescription.h"
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

- (void)_updateParameters;
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
    [_itemMesh addObserver:self forKeyPath:@"isVisible" options:NSKeyValueObservingOptionNew context:NULL];
	if (![self _updateShaderError:error])
		return nil;
	
    [self _updateParameters];
    
	glGenBuffers(1, &renderParametersBuffer);
	[self _updateParameters];
	
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
	
    [_itemMesh removeObserver:self forKeyPath:@"isVisible"];
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

        [self _updateParameters];
        [self.itemDrawer propertiesChanged];
	}
	else if ([keyPath isEqual:@"uniformValue"])
	{
        [self _updateParameters];
        [self.itemDrawer propertiesChanged];
	}
    else if ([keyPath isEqual:@"isVisible"])
    {
        [self.itemDrawer propertiesChanged];
    }
	else if ([keyPath isEqual:@"textures"])
	{
		for (GLLItemMeshTexture *texture in textureAssignments)
			[texture removeObserver:self forKeyPath:@"textureURL"];
		
		textureAssignments = [_itemMesh.textures copy];
		for (GLLItemMeshTexture *texture in textureAssignments)
            [texture addObserver:self forKeyPath:@"textureURL" options:NSKeyValueObservingOptionNew context:NULL];
        [self.itemDrawer propertiesChanged];
	}
	else if ([keyPath isEqual:@"textureURL"])
	{
        needsTextureUpdate = YES;
        [self.itemDrawer propertiesChanged];
	}
	else if ([keyPath isEqual:@"shaderName"])
	{
		needsTextureUpdate = YES;
		needsProgramUpdate = YES;
        [self.itemDrawer propertiesChanged];
	}
	else
		[super observeValueForKeyPath:keyPath ofObject:object change:change context:context];
}

- (void)setupState:(GLLDrawState *)state;
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
        GLuint textureId = [textures[i] textureID];
        if (i >= GLL_DRAW_STATE_MAX_ACTIVE_TEXTURES || state->activeTexture[i] != textureId) {
            glActiveTexture(GL_TEXTURE0 + (GLenum) i);
            glBindTexture(GL_TEXTURE_2D, textureId);
            if (i < GLL_DRAW_STATE_MAX_ACTIVE_TEXTURES)
                state->activeTexture[i] = textureId;
        }
	}
	
	// Use this program, with the correct transformation.
	if (state->activeProgram != self.program.programID)
	{
		glUseProgram(self.program.programID);
		state->activeProgram = self.program.programID;
	}
    
    if (state->activeVertexArray != self.meshDrawer.vertexArray) {
        glBindVertexArray(self.meshDrawer.vertexArray);
        state->activeVertexArray = self.meshDrawer.vertexArray;
    }
}

- (void)unload
{
	glDeleteBuffers(1, &renderParametersBuffer);
	renderParametersBuffer = 0;
	
	renderParameters = nil;
}

- (NSComparisonResult)compareTo:(GLLItemMeshDrawer *)other {
    if (self.itemMesh.cullFaceMode > other.itemMesh.cullFaceMode)
        return NSOrderedAscending;
    else if (self.itemMesh.cullFaceMode < other.itemMesh.cullFaceMode)
        return NSOrderedDescending;
    
    NSComparisonResult result = [self.meshDrawer compareTo:other.meshDrawer];
    if (result != NSOrderedSame)
        return result;
    
    if (self.program.programID != other.program.programID) {
        return self.program.programID > other.program.programID ? NSOrderedDescending : NSOrderedAscending;
    }
    
    if (textures.count != other->textures.count) {
        return textures.count > other->textures.count ? NSOrderedDescending : NSOrderedAscending;
    }
    
    for (NSUInteger i = 0; i < textures.count; i++) {
        if (textures[i] > other->textures[i])
            return NSOrderedDescending;
        else if (textures[i] < other->textures[i])
            return NSOrderedAscending;
    }

    // Check render parameters by comparing the buffers.
    NSData *otherData = other.parameterBufferData;
    NSData *parameterData = self.parameterBufferData;
    if (otherData.length < parameterData.length)
        return NSOrderedDescending;
    else if (otherData.length > parameterData.length)
        return NSOrderedAscending;
    else {
        int result = memcmp(parameterData.bytes, otherData.bytes, otherData.length);
        if (result < 0)
            return NSOrderedAscending;
        else if (result > 0)
            return NSOrderedDescending;
        else
            return NSOrderedSame;
    }
}

#pragma mark - Private methods

- (void)_updateParameters;
{
    NSUInteger bufferLength = self.program.renderParametersBufferSize;
    uint8_t *data = calloc(1, bufferLength);
    for (GLLRenderParameter *parameter in self.itemMesh.renderParameters)
    {
        NSInteger byteOffset = [self.program offsetForUniform:parameter.name inBlock:@"RenderParameters"];
        if (byteOffset < 0)
            continue;
        
        [parameter.uniformValue getBytes:data + byteOffset length:bufferLength - byteOffset];
    }
    [self willChangeValueForKey:@"parameterBufferData"];
    _parameterBufferData = [[NSData alloc] initWithBytesNoCopy:data length:bufferLength freeWhenDone:YES];
    needsParameterBufferUpdate = YES;
    [self didChangeValueForKey:@"parameterBufferData"];
}

- (void)_updateParameterBuffer;
{
	if (!_program)
		return;
	
	if (self.program.renderParametersUniformBlockIndex == GL_INVALID_INDEX)
		return;
    
    glBindBufferBase(GL_UNIFORM_BUFFER, GLLUniformBlockBindingRenderParameters, renderParametersBuffer);
    glBufferData(GL_UNIFORM_BUFFER, _parameterBufferData.length, NULL, GL_STREAM_DRAW);
    glBufferSubData(GL_UNIFORM_BUFFER, 0, _parameterBufferData.length, _parameterBufferData.bytes);

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
	needsTextureUpdate = YES;
	needsProgramUpdate = NO;
	
	if (self.itemMesh.shaderName == nil)
	{
		// Allow empty programs for objects
		// that don't have a shader.
		_program = nil;
		return YES;
	}
	
    _program = [[GLLResourceManager sharedResourceManager] programForDescriptor:self.itemMesh.shader withAlpha:self.itemMesh.mesh.usesAlphaBlending error:error];
	if (!self.program)
		return NO;
    
    [self _updateParameters];
	return YES;
}

@end
