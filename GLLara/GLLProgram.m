//
//  GLLProgram.m
//
//
//  Created by Torsten Kammer on 14.09.12.
//
//

#import "GLLProgram.h"

#import <OpenGL/gl3.h>

#import "GLLResourceManager.h"
#import "GLLShader.h"

@interface GLLProgram () {
	NSMutableDictionary *uniformOffsets;
}

@end

@implementation GLLProgram

- (id)initWithFragmentShaderName:(NSString *)fragmentName geometryShaderName:(NSString *)geometryName vertexShaderName:(NSString *)vertexName additionalDefines:(NSDictionary *)additionalDefines usedTexCoords:(NSIndexSet *)texCoords resourceManager:(GLLResourceManager *)manager error:(NSError *__autoreleasing*)error;
{
	GLLShader *vertex, *fragment, *geometry;
	if (vertexName)
	{
		vertex = [manager shaderForName:vertexName additionalDefines:additionalDefines usedTexCoords:texCoords type:GL_VERTEX_SHADER error:error];
		if (!vertex)
		{
			[self unload];
			return nil;
		}
	}
	if (geometryName)
	{
		fragment = [manager shaderForName:geometryName additionalDefines:additionalDefines usedTexCoords:texCoords type:GL_GEOMETRY_SHADER error:error];
		if (!fragment)
		{
			[self unload];
			return nil;
		}
	}
	if (fragmentName)
	{
		fragment = [manager shaderForName:fragmentName additionalDefines:additionalDefines usedTexCoords:texCoords type:GL_FRAGMENT_SHADER error:error];
		if (!fragment)
		{
			[self unload];
			return nil;
		}
	}
	
	return [self initWithFragmentShader:fragment geometryShader:geometry vertexShader:vertex error:error];
}

- (id)initWithFragmentShader:(GLLShader *)fragment geometryShader:(GLLShader *)geometry vertexShader:(GLLShader *)vertex error:(NSError *__autoreleasing*)error;
{
	if (!(self = [super init])) return nil;
	
	uniformOffsets = [[NSMutableDictionary alloc] init];
	
	_programID = glCreateProgram();
	if (vertex)
		glAttachShader(_programID, vertex.shaderID);
	if (fragment)
		glAttachShader(_programID, fragment.shaderID);
	if (geometry)
		glAttachShader(_programID, geometry.shaderID);
	
	[self bindAttributeLocations];
	
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
		
		if (error)
			*error = [NSError errorWithDomain:@"OpenGL" code:1 userInfo:@{ NSLocalizedDescriptionKey : [NSString stringWithFormat:NSLocalizedString(@"The shader could not be linked", @"GLLShader error message description")],
																		   NSLocalizedFailureReasonErrorKey : [NSString stringWithFormat:NSLocalizedString(@"Message from OpenGL driver: %s", "No shader there wtf?"), log],
																		   NSLocalizedRecoverySuggestionErrorKey : NSLocalizedString(@"Please inform a developer of this problem.", @"No shader there wtf?")
																		   }];
		NSLog(@"link error in shader: %s", log);
		[self unload];
		return nil;
	}
	
	return self;
}

- (void)bindAttributeLocations;
{
	
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

- (NSInteger)offsetForUniform:(NSString *)uniformName inBlock:(NSString *)blockName
{
	return [self offsetForUniform:[NSString stringWithFormat:@"%@.%@", blockName, uniformName]];
}

- (NSInteger)offsetForUniform:(NSString *)uniformName
{
	NSNumber *result = uniformOffsets[uniformName];
	if (!result) {
		GLuint uniformIndex;
		glGetUniformIndices(self.programID, 1, (const GLchar *[]) { uniformName.UTF8String }, &uniformIndex);
		if (uniformIndex == GL_INVALID_INDEX) {
			result = @(-1);
		} else {
			GLint byteOffset;
			glGetActiveUniformsiv(self.programID, 1, &uniformIndex, GL_UNIFORM_OFFSET, &byteOffset);
			result = @(byteOffset);
		}
		uniformOffsets[uniformName] = result;
	}
	return result.integerValue;
}

@end
