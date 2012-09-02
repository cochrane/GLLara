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
	
	glBindAttribLocation(_programID, GLLVertexAttribPosition, "Position");
	glBindAttribLocation(_programID, GLLVertexAttribNormal, "Normal");
	glBindAttribLocation(_programID, GLLVertexAttribColor, "Color");
	glBindAttribLocation(_programID, GLLVertexAttribTexCoord0, "TexCoord");
	glBindAttribLocation(_programID, GLLVertexAttribTangent0, "Tangent");
	glBindAttribLocation(_programID, GLLVertexAttribTexCoord0+2, "TexCoord2");
	glBindAttribLocation(_programID, GLLVertexAttribBoneIndices, "BoneIndices");
	glBindAttribLocation(_programID, GLLVertexAttribBoneWeights, "BoneWeights");
	
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
