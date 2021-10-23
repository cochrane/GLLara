//
//  GLLProgram.m
//  GLLara
//
//  Created by Torsten Kammer on 02.09.12.
//  Copyright (c) 2012 Torsten Kammer. All rights reserved.
//

#import "GLLModelProgram.h"

#import <OpenGL/gl3.h>

#import "GLLNotifications.h"
#import "GLLShader.h"
#import "GLLVertexFormat.h"
#import "GLLUniformBlockBindings.h"
#import "GLLResourceManager.h"

#import "GLLara-Swift.h"

@interface GLLModelProgram()

@property (nonatomic, copy) NSIndexSet *texCoords;

@end

@implementation GLLModelProgram

- (id)initWithDescriptor:(GLLShaderData *)descriptor resourceManager:(GLLResourceManager *)manager error:(NSError *__autoreleasing*)error;
{
    NSMutableIndexSet *texCoords = [[NSMutableIndexSet alloc] init];
    [texCoords addIndex:0]; // Always present as a default
    for (NSNumber *number in descriptor.texCoordAssignments)
        [texCoords addIndex:number.integerValue];
    self.texCoords = texCoords;
    
    NSMutableDictionary<NSString *, NSString *> *additionalDefines = [[NSMutableDictionary alloc] init];
    if (descriptor.alphaBlending) {
        additionalDefines[@"USE_ALPHA_TEST"] = @"1";
    }
    if (descriptor.parameterUniforms.count > 0) {
        additionalDefines[@"RENDER_PARAMETERS"] = @"1";
    }
    [additionalDefines addEntriesFromDictionary:descriptor.defines];
    
    for (NSString *textureUniformName in descriptor.textureUniforms) {
        NSString *defineName = [NSString stringWithFormat:descriptor.base.texCoordDefineFormat, textureUniformName];
        additionalDefines[defineName] = [NSString stringWithFormat:descriptor.base.texCoordVarNameFormat, [descriptor texCoordSetForTexture:textureUniformName]];
    }
    
    if (!(self = [super initWithFragmentShaderName:descriptor.fragmentName geometryShaderName:descriptor.geometryName vertexShaderName:descriptor.vertexName additionalDefines:additionalDefines usedTexCoords:texCoords resourceManager:manager error:error])) return nil;
    
    _lightsUniformBlockIndex = glGetUniformBlockIndex(self.programID, "LightData");
    if (_lightsUniformBlockIndex != GL_INVALID_INDEX) glUniformBlockBinding(self.programID, _lightsUniformBlockIndex, GLLUniformBlockBindingLights);
    
    _renderParametersUniformBlockIndex = glGetUniformBlockIndex(self.programID, "RenderParameters");
    if (_renderParametersUniformBlockIndex != GL_INVALID_INDEX) {
        glUniformBlockBinding(self.programID, _renderParametersUniformBlockIndex, GLLUniformBlockBindingRenderParameters);
        glGetActiveUniformBlockiv(self.programID, self.renderParametersUniformBlockIndex, GL_UNIFORM_BLOCK_DATA_SIZE, &_renderParametersBufferSize);
    } else {
        _renderParametersBufferSize = 0;
    }
    
    _transformUniformBlockIndex = glGetUniformBlockIndex(self.programID, "Transform");
    if (_transformUniformBlockIndex != GL_INVALID_INDEX) glUniformBlockBinding(self.programID, _transformUniformBlockIndex, GLLUniformBlockBindingTransforms);
    
    _alphaTestUniformBlockIndex = glGetUniformBlockIndex(self.programID, "AlphaTest");
    if (_alphaTestUniformBlockIndex != GL_INVALID_INDEX) glUniformBlockBinding(self.programID, _alphaTestUniformBlockIndex, GLLUniformBlockBindingAlphaTest);
    
    _boneMatricesUniformBlockIndex = glGetUniformBlockIndex(self.programID, "Bones");
    if (_boneMatricesUniformBlockIndex != GL_INVALID_INDEX) glUniformBlockBinding(self.programID, _boneMatricesUniformBlockIndex, GLLUniformBlockBindingBoneMatrices);
    
    // Set up textures. Uniforms for textures need to be set up once and then never change, because uniforms bind to texture units, not texture objects. I really, really wish I knew whom that is supposed to help, but whatever.
    glUseProgram(self.programID);
    for (GLint i = 0; i < (GLint) descriptor.textureUniforms.count; i++)
    {
        GLint location = glGetUniformLocation(self.programID, [descriptor.textureUniforms[i] UTF8String]);
        if (location == -1) continue;
        glUniform1i(location, i);
    }
    
    glUseProgram(0);
    [[NSNotificationCenter defaultCenter] postNotificationName:GLLDrawStateChangedNotification object:self];
    
    return self;
}

- (void)bindAttributeLocations;
{
    
    glBindAttribLocation(self.programID, GLLVertexAttribPosition, "position");
    glBindAttribLocation(self.programID, GLLVertexAttribNormal, "normal");
    glBindAttribLocation(self.programID, GLLVertexAttribColor, "color");
    glBindAttribLocation(self.programID, GLLVertexAttribBoneIndices, "boneIndices");
    glBindAttribLocation(self.programID, GLLVertexAttribBoneWeights, "boneWeights");
    
    for (NSInteger index = self.texCoords.firstIndex; index != NSNotFound; index = [self.texCoords indexGreaterThanIndex:index]) {
        glBindAttribLocation(self.programID, (GLuint) (GLLVertexAttribTexCoord0 + 2*index), [NSString stringWithFormat:@"texCoord%ld", index].UTF8String);
        glBindAttribLocation(self.programID, (GLuint) (GLLVertexAttribTangent0 + 2*index), [NSString stringWithFormat:@"tangent%ld", index].UTF8String);
    }
}

@end
