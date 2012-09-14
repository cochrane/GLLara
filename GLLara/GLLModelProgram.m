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
#import "GLLShaderDescription.h"
#import "GLLVertexFormat.h"
#import "GLLUniformBlockBindings.h"
#import "GLLResourceManager.h"

@implementation GLLProgram

- (id)initWithDescriptor:(GLLShaderDescription *)descriptor resourceManager:(GLLResourceManager *)manager error:(NSError *__autoreleasing*)error;
{
	if (!(self = [super init])) return nil;
	
	_name = descriptor.name;
	
	if (!descriptor.fragmentName)
	{
		if (error)
			*error = [NSError errorWithDomain:@"OpenGL" code:1 userInfo:@{ NSLocalizedDescriptionKey : [NSString stringWithFormat:NSLocalizedString(@"Shader \"%@\" lacks fragment shader", @"GLLShader no source message description"), _name],
				 NSLocalizedRecoverySuggestionErrorKey : NSLocalizedString(@"Please inform a developer of this problem.", @"No shader there wtf?")
									  }];
		return nil;
	}
	if (!descriptor.vertexName)
	{
		if (error)
			*error = [NSError errorWithDomain:@"OpenGL" code:1 userInfo:@{ NSLocalizedDescriptionKey : [NSString stringWithFormat:NSLocalizedString(@"Shader \"%@\" lacks vertex shader", @"GLLShader no source message description"), _name],
	   NSLocalizedRecoverySuggestionErrorKey : NSLocalizedString(@"Please inform a developer of this problem.", @"No shader there wtf?")
					  }];
		return nil;
	}
	
	_programID = glCreateProgram();
	if (descriptor.vertexName)
	{
		GLLShader *shader = [manager shaderForName:descriptor.vertexName type:GL_VERTEX_SHADER baseURL:descriptor.baseURL error:error];
		if (!shader)
		{
			[self unload];
			return nil;
		}
		glAttachShader(_programID, shader.shaderID);
	}
	if (descriptor.geometryName)
	{
		GLLShader *shader = [manager shaderForName:descriptor.geometryName type:GL_GEOMETRY_SHADER baseURL:descriptor.baseURL error:error];
		if (!shader)
		{
			[self unload];
			return nil;
		}
		glAttachShader(_programID, shader.shaderID);
	}
	if (descriptor.fragmentName)
	{
		GLLShader *shader = [manager shaderForName:descriptor.fragmentName type:GL_FRAGMENT_SHADER baseURL:descriptor.baseURL error:error];
		if (!shader)
		{
			[self unload];
			return nil;
		}
		glAttachShader(_programID, shader.shaderID);
	}
	
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
		
		if (error)
			*error = [NSError errorWithDomain:@"OpenGL" code:1 userInfo:@{ NSLocalizedDescriptionKey : [NSString stringWithFormat:NSLocalizedString(@"The shader \"%@\" could not be linked", @"GLLShader error message description"), _name],
			NSLocalizedFailureReasonErrorKey : [NSString stringWithFormat:NSLocalizedString(@"Message from OpenGL driver: %s", log)],
	   NSLocalizedRecoverySuggestionErrorKey : NSLocalizedString(@"Please inform a developer of this problem.", @"No shader there wtf?")
					  }];
		NSLog(@"link error in shader %@: %s", _name, log);
		[self unload];
		return nil;
	}
	
	_lightsUniformBlockIndex = glGetUniformBlockIndex(_programID, "LightData");
	if (_lightsUniformBlockIndex != GL_INVALID_INDEX) glUniformBlockBinding(_programID, _lightsUniformBlockIndex, GLLUniformBlockBindingLights);

	_renderParametersUniformBlockIndex = glGetUniformBlockIndex(_programID, "RenderParameters");
	if (_renderParametersUniformBlockIndex != GL_INVALID_INDEX) glUniformBlockBinding(_programID, _renderParametersUniformBlockIndex, GLLUniformBlockBindingRenderParameters);

	_transformUniformBlockIndex = glGetUniformBlockIndex(_programID, "Transform");
	if (_transformUniformBlockIndex != GL_INVALID_INDEX) glUniformBlockBinding(_programID, _transformUniformBlockIndex, GLLUniformBlockBindingTransforms);
	
	_alphaTestUniformBlockIndex = glGetUniformBlockIndex(_programID, "AlphaTest");
	if (_alphaTestUniformBlockIndex != GL_INVALID_INDEX) glUniformBlockBinding(_programID, _alphaTestUniformBlockIndex, GLLUniformBlockBindingAlphaTest);
	
	_boneMatricesUniformBlockIndex = glGetUniformBlockIndex(_programID, "Bones");
	if (_boneMatricesUniformBlockIndex != GL_INVALID_INDEX) glUniformBlockBinding(_programID, _boneMatricesUniformBlockIndex, GLLUniformBlockBindingBoneMatrices);
	
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
