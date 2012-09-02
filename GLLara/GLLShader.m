//
//  GLLShader.m
//  GLLara
//
//  Created by Torsten Kammer on 02.09.12.
//  Copyright (c) 2012 Torsten Kammer. All rights reserved.
//

#import "GLLShader.h"

#import <OpenGL/gl3.h>

@implementation GLLShader

- (id)initWithSource:(NSString *)sourceString type:(GLenum)type;
{
	if (!(self = [super init])) return nil;
	
	_shaderID = glCreateShader(type);
	const GLchar *source = [sourceString UTF8String];
	const GLsizei length = (GLsizei) strlen(source);
	glShaderSource(_shaderID, 1, &source, &length);
	glCompileShader(_shaderID);
	
	GLint compileStatus;
	glGetShaderiv(_shaderID, GL_COMPILE_STATUS, &compileStatus);
	if (compileStatus != GL_TRUE)
	{
		GLsizei length;
		glGetShaderiv(_shaderID, GL_INFO_LOG_LENGTH, &length);
		GLchar log[length+1];
		glGetShaderInfoLog(_shaderID, length+1, NULL, log);
		log[length] = '\0';
		
		[NSException raise:NSInvalidArgumentException format:@"Could not compile shader. Log: %s", log];
	}
	
	return self;
}

- (void)dealloc
{
	NSAssert(_shaderID == 0 && _type == 0, @"Did not call unload before deallocating");
}

- (void)unload;
{
	glDeleteShader(self.shaderID);
	_shaderID = 0;
	_type = 0;
}

@end
