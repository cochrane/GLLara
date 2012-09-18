//
//  GLLProgram.m
//  GLLara
//
//  Created by Torsten Kammer on 02.09.12.
//  Copyright (c) 2012 Torsten Kammer. All rights reserved.
//

#import "GLLModelProgram.h"

#import <OpenGL/gl3.h>

#import "GLLShader.h"
#import "GLLShaderDescription.h"
#import "GLLVertexFormat.h"
#import "GLLUniformBlockBindings.h"
#import "GLLResourceManager.h"
#import "LionSubscripting.h"

@implementation GLLModelProgram

- (id)initWithDescriptor:(GLLShaderDescription *)descriptor resourceManager:(GLLResourceManager *)manager error:(NSError *__autoreleasing*)error;
{
	if (!(self = [super initWithName:descriptor.name fragmentShaderName:descriptor.fragmentName geometryShaderName:descriptor.geometryName vertexShaderName:descriptor.vertexName baseURL:descriptor.baseURL resourceManager:manager error:error])) return nil;
	
	_lightsUniformBlockIndex = glGetUniformBlockIndex(self.programID, "LightData");
	if (_lightsUniformBlockIndex != GL_INVALID_INDEX) glUniformBlockBinding(self.programID, _lightsUniformBlockIndex, GLLUniformBlockBindingLights);

	_renderParametersUniformBlockIndex = glGetUniformBlockIndex(self.programID, "RenderParameters");
	if (_renderParametersUniformBlockIndex != GL_INVALID_INDEX) glUniformBlockBinding(self.programID, _renderParametersUniformBlockIndex, GLLUniformBlockBindingRenderParameters);

	_transformUniformBlockIndex = glGetUniformBlockIndex(self.programID, "Transform");
	if (_transformUniformBlockIndex != GL_INVALID_INDEX) glUniformBlockBinding(self.programID, _transformUniformBlockIndex, GLLUniformBlockBindingTransforms);
	
	_alphaTestUniformBlockIndex = glGetUniformBlockIndex(self.programID, "AlphaTest");
	if (_alphaTestUniformBlockIndex != GL_INVALID_INDEX) glUniformBlockBinding(self.programID, _alphaTestUniformBlockIndex, GLLUniformBlockBindingAlphaTest);
	
	_boneMatricesUniformBlockIndex = glGetUniformBlockIndex(self.programID, "Bones");
	if (_boneMatricesUniformBlockIndex != GL_INVALID_INDEX) glUniformBlockBinding(self.programID, _boneMatricesUniformBlockIndex, GLLUniformBlockBindingBoneMatrices);
	
	// Set up textures. Uniforms for textures need to be set up once and then never change, because uniforms bind to texture units, not texture objects. I really, really wish I knew whom that is supposed to help, but whatever.
	glUseProgram(self.programID);
	for (GLint i = 0; i < (GLint) descriptor.textureUniformNames.count; i++)
	{
		GLint location = glGetUniformLocation(self.programID, [descriptor.textureUniformNames[i] UTF8String]);
		if (location == -1) continue;
		glUniform1i(location, i);
	}
	
	glUseProgram(0);
	
	return self;
}

- (void)bindAttributeLocations;
{
	glBindAttribLocation(self.programID, GLLVertexAttribPosition, "position");
	glBindAttribLocation(self.programID, GLLVertexAttribNormal, "normal");
	glBindAttribLocation(self.programID, GLLVertexAttribColor, "color");
	glBindAttribLocation(self.programID, GLLVertexAttribTexCoord0, "texCoord");
	glBindAttribLocation(self.programID, GLLVertexAttribTangent0, "tangent");
	glBindAttribLocation(self.programID, GLLVertexAttribTexCoord0+2, "texCoord2");
	glBindAttribLocation(self.programID, GLLVertexAttribBoneIndices, "boneIndices");
	glBindAttribLocation(self.programID, GLLVertexAttribBoneWeights, "boneWeights");	
}

@end
