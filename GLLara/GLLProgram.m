//
//  GLLProgram.m
//  GLLara
//
//  Created by Torsten Kammer on 02.09.12.
//  Copyright (c) 2012 Torsten Kammer. All rights reserved.
//

#import "GLLProgram.h"

#import <OpenGL/gl3.h>

#import "GLLShader.h"
#import "GLLShaderDescriptor.h"
#import "GLLVertexFormat.h"
#import "GLLUniformBlockBindings.h"
#import "GLLResourceManager.h"

@implementation GLLProgram

- (id)initWithDescriptor:(GLLShaderDescriptor *)descriptor resourceManager:(GLLResourceManager *)manager;
{
	if (!(self = [super init])) return nil;
	
	_programID = glCreateProgram();
	if (descriptor.vertexName)
		glAttachShader(_programID, [manager shaderForName:descriptor.vertexName type:GL_VERTEX_SHADER baseURL:descriptor.baseURL].shaderID);
	if (descriptor.geometryName)
		glAttachShader(_programID, [manager shaderForName:descriptor.geometryName type:GL_GEOMETRY_SHADER baseURL:descriptor.baseURL].shaderID);
	if (descriptor.fragmentName)
		glAttachShader(_programID, [manager shaderForName:descriptor.fragmentName type:GL_FRAGMENT_SHADER baseURL:descriptor.baseURL].shaderID);
	
	glBindAttribLocation(_programID, GLLVertexAttribPosition, "position");
	glBindAttribLocation(_programID, GLLVertexAttribNormal, "normal");
	glBindAttribLocation(_programID, GLLVertexAttribColor, "color");
	glBindAttribLocation(_programID, GLLVertexAttribTexCoord0, "texCoord");
	glBindAttribLocation(_programID, GLLVertexAttribTangent0, "tangent");
	glBindAttribLocation(_programID, GLLVertexAttribTexCoord0+2, "texCoord2");
	glBindAttribLocation(_programID, GLLVertexAttribBoneIndices, "boneIndices");
	glBindAttribLocation(_programID, GLLVertexAttribBoneWeights, "boneWeights");
	
	glLinkProgram(_programID);
	
	GLint linkStatus;
	glGetProgramiv(_programID, GL_LINK_STATUS, &linkStatus);
	if (linkStatus != GL_TRUE)
	{
		GLsizei length;
		glGetProgramiv(_programID, GL_INFO_LOG_LENGTH, &length);
		GLchar log[length+1];
		glGetProgramInfoLog(_programID, length+1, NULL, log);
		log[length] = '\0';
		
		[NSException raise:NSInvalidArgumentException format:@"Could not link shaders to program. Log: %s", log];
	}
	
	_boneMatricesUniformLocation = glGetUniformLocation(_programID, "boneMatrices");
	_lightsUniformBlockIndex = glGetUniformBlockIndex(_programID, "lights");
	_renderParametersUniformBlockIndex = glGetUniformBlockIndex(_programID, "renderParameters");
	_transformUniformBlockIndex = glGetUniformBlockIndex(_programID, "transform");
	
	glUniformBlockBinding(_programID, _renderParametersUniformBlockIndex, GLLUniformBlockBindingRenderParameters);
	glUniformBlockBinding(_programID, _lightsUniformBlockIndex, GLLUniformBlockBindingLights);
	glUniformBlockBinding(_programID, _transformUniformBlockIndex, GLLUniformBlockBindingTransforms);
	
	// Set up textures. Uniforms for textures need to be set up once and then never change, because uniforms bind to texture units, not texture objects. I really, really wish I knew whom that is supposed to help, but whatever.
	glUseProgram(_programID);
	for (GLint i = 0; i < (GLint) descriptor.textureUniformNames.count; i++)
	{
		GLint location = glGetUniformLocation(_programID, [descriptor.textureUniformNames[i] UTF8String]);
		if (location == -1) continue;
		glUniform1i(location, i);
	}
	
	glUseProgram(0);
	
	return self;
}

- (void)dealloc
{
	NSAssert(_programID == 0, @"Did not call unload before deallocing.");
}

- (void)unload;
{
	glDeleteProgram(_programID);
	_programID = 0;
}

@end
