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

- (id)initWithSource:(NSString *)sourceString name:(NSString *)name type:(GLenum)type error:(NSError *__autoreleasing*)error;
{
	if (!(self = [super init])) return nil;
	
	if (!sourceString)
	{
		if (error)
			*error = [NSError errorWithDomain:@"OpenGL" code:1 userInfo:@{ NSLocalizedDescriptionKey : [NSString stringWithFormat:NSLocalizedString(@"The source code shader \"%@\" could not be found", @"GLLShader no source message description"), name],
	   NSLocalizedRecoverySuggestionErrorKey : NSLocalizedString(@"Please inform a developer of this problem.", @"No shader there wtf?")
					  }];
		return nil;
	}
	
	_name = [name copy];
	
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
		
		if (error)
			*error = [NSError errorWithDomain:@"OpenGL" code:1 userInfo:@{ NSLocalizedDescriptionKey : [NSString stringWithFormat:NSLocalizedString(@"The shader \"%@\" could not be compiled properly", @"GLLShader error message description"), name],
			NSLocalizedFailureReasonErrorKey : [NSString stringWithFormat:NSLocalizedString(@"Message from OpenGL driver: %s", log)],
	   NSLocalizedRecoverySuggestionErrorKey : NSLocalizedString(@"Please inform a developer of this problem.", @"No shader there wtf?")
					  }];
		NSLog(@"compile error in shader %@: %s", _name, log);
		[self unload];
		return nil;
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
