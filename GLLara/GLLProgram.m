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
#import "GLLVertexFormat.h"
#import "GLLUniformBlockBindings.h"

@implementation GLLProgram

- (id)initWithVertexShader:(GLLShader *)vertex geometryShader:(GLLShader *)geometry fragmentShader:(GLLShader *)fragment;
{
	if (!(self = [super init])) return nil;
	
	_programID = glCreateProgram();
	if (vertex)
		glAttachShader(_programID, vertex.shaderID);
	if (geometry)
		glAttachShader(_programID, geometry.shaderID);
	if (fragment)
		glAttachShader(_programID, fragment.shaderID);
	
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
