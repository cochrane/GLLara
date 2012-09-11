//
//  GLLTransformedMeshDrawer.m
//  GLLara
//
//  Created by Torsten Kammer on 06.09.12.
//  Copyright (c) 2012 Torsten Kammer. All rights reserved.
//

#import "GLLTransformedMeshDrawer.h"

#import <OpenGL/gl3.h>

#import "GLLMeshDrawer.h"
#import "GLLMeshSettings.h"
#import "GLLProgram.h"
#import "GLLRenderParameter.h"
#import "GLLUniformBlockBindings.h"

@interface GLLTransformedMeshDrawer ()
{
	GLuint renderParametersBuffer;
}

@end

@implementation GLLTransformedMeshDrawer

- (id)initWithDrawer:(GLLMeshDrawer *)drawer settings:(GLLMeshSettings *)settings;
{
	if (!(self = [super init])) return nil;
	
	NSAssert(drawer != nil && settings != nil, @"Have to have drawer and settings.");
	
	_drawer = drawer;
	_settings = settings;
	
	// If there are render parameters to be set, create a uniform buffer for them and set their values from the mesh.
	if (drawer.program.renderParametersUniformBlockIndex != GL_INVALID_INDEX)
	{
		GLint bufferLength;
		glGetActiveUniformBlockiv(drawer.program.programID, drawer.program.renderParametersUniformBlockIndex, GL_UNIFORM_BLOCK_DATA_SIZE, &bufferLength);
		void *data = malloc(bufferLength);
		
		for (GLLRenderParameter *parameter in settings.renderParameters)
		{
			NSString *fullName = [@"RenderParameters." stringByAppendingString:parameter.name];
			GLuint uniformIndex;
			glGetUniformIndices(drawer.program.programID, 1, (const GLchar *[]) { fullName.UTF8String }, &uniformIndex);
			if (uniformIndex == GL_INVALID_INDEX) continue;
			
			GLint byteOffset;
			glGetActiveUniformsiv(drawer.program.programID, 1, &uniformIndex, GL_UNIFORM_OFFSET, &byteOffset);
			
			*((float *) &data[byteOffset]) = parameter.value;
			
			[parameter addObserver:self forKeyPath:@"value" options:NSKeyValueObservingOptionNew context:NULL];
		}
		
		glGenBuffers(1, &renderParametersBuffer);
		glBindBuffer(GL_UNIFORM_BUFFER, renderParametersBuffer);
		glBufferData(GL_UNIFORM_BUFFER, bufferLength, data, GL_STATIC_DRAW);
		
		free(data);
	}
	
	return self;
}

- (void)observeValueForKeyPath:(NSString *)keyPath ofObject:(id)object change:(NSDictionary *)change context:(void *)context
{
	if ([keyPath isEqual:@"value"])
	{
		if ([object valueForKey:@"name"] == nil)
		{
			[object removeObserver:self forKeyPath:@"value"];
			return;
		}
		if (self.drawer.program.renderParametersUniformBlockIndex == GL_INVALID_INDEX) return;
		
		// Can ignore the OpenGL Context here, because all contexts will share all buffers with the one we need, so the right value is going to get there, definitely.
		
		NSString *fullName = [@"RenderParameters." stringByAppendingString:[object valueForKey:@"name"]];
		GLuint uniformIndex;
		glGetUniformIndices(self.drawer.program.programID, 1, (const GLchar *[]) { fullName.UTF8String }, &uniformIndex);
		if (uniformIndex == GL_INVALID_INDEX) return;
		
		GLint byteOffset;
		glGetActiveUniformsiv(self.drawer.program.programID, 1, &uniformIndex, GL_UNIFORM_OFFSET, &byteOffset);
		
		GLfloat value = [change[NSKeyValueChangeNewKey] floatValue];
		glBindBuffer(GL_UNIFORM_BUFFER, renderParametersBuffer);
		glBufferSubData(GL_UNIFORM_BUFFER, byteOffset, sizeof(value), &value);
	}
	else
		[super observeValueForKeyPath:@"keyPath" ofObject:object change:change context:context];
}

- (void)draw;
{
	if (!self.settings.isVisible)
		return;
	
	switch (self.settings.cullFaceMode)
	{
		case GLLCullBack:
			glCullFace(GL_BACK);
			break;
			
		case GLLCullFront:
			glCullFace(GL_FRONT);
			break;
			
		case GLLCullNone:
			glDisable(GL_CULL_FACE);
			
		default:
			break;
	}
	
	// If there are render parameters, apply them
	if (renderParametersBuffer != 0)
		glBindBufferBase(GL_UNIFORM_BUFFER, GLLUniformBlockBindingRenderParameters, renderParametersBuffer);
	
	[self.drawer draw];
	
	// Enable it again.
	if (self.settings.cullFaceMode == GLLCullNone)
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
	for (GLLRenderParameter *parameter in self.settings.renderParameters)
		[parameter removeObserver:self forKeyPath:@"value"];
}

@end
