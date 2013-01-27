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
#import "GLLMeshDrawer.h"
#import "GLLModelMesh.h"
#import "GLLItemMesh.h"
#import "GLLModelProgram.h"
#import "GLLRenderParameter.h"
#import "GLLUniformBlockBindings.h"

@interface GLLItemMeshDrawer ()
{
	GLuint renderParametersBuffer;
	BOOL needsParameterBufferUpdate;
	NSMutableArray *renderParameters;
}
- (void)_updateParameterBuffer;

@end

@implementation GLLItemMeshDrawer

- (id)initWithItemDrawer:(GLLItemDrawer *)itemDrawer meshDrawer:(GLLMeshDrawer *)meshDrawer itemMesh:(GLLItemMesh *)itemMesh;
{
	if (!(self = [super init])) return nil;
	
	NSAssert(itemDrawer != nil && meshDrawer != nil && itemMesh != nil, @"None of this can be nil");
	
	_itemDrawer = itemDrawer;
	_meshDrawer = meshDrawer;
	_itemMesh = itemMesh;
	
	// If there are render parameters to be set, create a uniform buffer for them and set their values from the mesh.
	if (meshDrawer.program.renderParametersUniformBlockIndex != GL_INVALID_INDEX)
	{
		// Store the render parameters in our own container, because by the time unload is called, there is a chance that the relationship is already destroyed and we can't get them again.
		renderParameters = [[NSMutableArray alloc] initWithCapacity:self.itemMesh.renderParameters.count];
		glGenBuffers(1, &renderParametersBuffer);
		needsParameterBufferUpdate = YES;
		for (GLLRenderParameter *parameter in self.itemMesh.renderParameters)
		{
			[renderParameters addObject:parameter];
			[parameter addObserver:self forKeyPath:@"uniformValue" options:NSKeyValueObservingOptionNew context:NULL];
		}
	}
	
	return self;
}

- (void)observeValueForKeyPath:(NSString *)keyPath ofObject:(id)object change:(NSDictionary *)change context:(void *)context
{
	if ([keyPath isEqual:@"uniformValue"])
	{
		needsParameterBufferUpdate = YES;
		self.itemDrawer.needsRedraw = YES;
	}
	else
		[super observeValueForKeyPath:@"keyPath" ofObject:object change:change context:context];
}

- (void)draw;
{
	if (!self.itemMesh.isVisible)
		return;
	if (needsParameterBufferUpdate)
		[self _updateParameterBuffer];
	
	switch (self.itemMesh.cullFaceMode)
	{
		case GLLCullCounterClockWise:
			glFrontFace(GL_CW);
			break;
			
		case GLLCullClockWise:
			glFrontFace(GL_CCW);
			break;
			
		case GLLCullNone:
			glDisable(GL_CULL_FACE);
			
		default:
			break;
	}
	
	// If there are render parameters, apply them
	if (renderParametersBuffer != 0)
		glBindBufferBase(GL_UNIFORM_BUFFER, GLLUniformBlockBindingRenderParameters, renderParametersBuffer);
	
	[self.meshDrawer draw];
	
	// Enable it again.
	if (self.itemMesh.cullFaceMode == GLLCullNone)
		glEnable(GL_CULL_FACE);
}

- (void)dealloc
{
	NSAssert(renderParametersBuffer == 0, @"Did not call unload before calling dealloc!");
}

- (void)unload
{
	glDeleteBuffers(1, &renderParametersBuffer);
	renderParametersBuffer = 0;
	for (GLLRenderParameter *parameter in renderParameters)
		[parameter removeObserver:self forKeyPath:@"uniformValue"];
	
	renderParameters = nil;
}

#pragma mark - Private methods

- (void)_updateParameterBuffer;
{
	GLint bufferLength;
	glGetActiveUniformBlockiv(self.meshDrawer.program.programID, self.meshDrawer.program.renderParametersUniformBlockIndex, GL_UNIFORM_BLOCK_DATA_SIZE, &bufferLength);
	void *data = calloc(1, bufferLength);
	
	for (GLLRenderParameter *parameter in self.itemMesh.renderParameters)
	{
		NSString *fullName = [@"RenderParameters." stringByAppendingString:parameter.name];
		GLuint uniformIndex;
		glGetUniformIndices(self.meshDrawer.program.programID, 1, (const GLchar *[]) { fullName.UTF8String }, &uniformIndex);
		if (uniformIndex == GL_INVALID_INDEX) continue;
		
		GLint byteOffset;
		glGetActiveUniformsiv(self.meshDrawer.program.programID, 1, &uniformIndex, GL_UNIFORM_OFFSET, &byteOffset);
		
		[parameter.uniformValue getBytes:&data[byteOffset]];
	}
	
	glBindBufferBase(GL_UNIFORM_BUFFER, GLLUniformBlockBindingRenderParameters, renderParametersBuffer);
	glBufferData(GL_UNIFORM_BUFFER, bufferLength, data, GL_STREAM_DRAW);
	
	free(data);

	needsParameterBufferUpdate = NO;
}

@end
