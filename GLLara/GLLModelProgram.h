//
//  GLLProgram.h
//  GLLara
//
//  Created by Torsten Kammer on 02.09.12.
//  Copyright (c) 2012 Torsten Kammer. All rights reserved.
//

#import <Foundation/Foundation.h>
#import <OpenGL/gltypes.h>

@class GLLShader;
@class GLLShaderDescription;
@class GLLResourceManager;

#import "GLLProgram.h"

/*!
 * @abstract A GLSL program, used by the default rendering path.
 * @discussion This class specifically sets up the buffers, binds the textures to the texture units, does linking and so on. It is written specifically for the model shaders. Other special effects shaders will need a different subclass of GLLProgram.
 */
@interface GLLModelProgram : GLLProgram

- (id)initWithDescriptor:(GLLShaderDescription *)descriptor resourceManager:(GLLResourceManager *)manager error:(NSError *__autoreleasing*)error;

// Uniforms set by model
@property (nonatomic, assign, readonly) GLuint boneMatricesUniformBlockIndex;

// Uniforms set by mesh
@property (nonatomic, assign, readonly) GLuint renderParametersUniformBlockIndex;

// Uniforms set by scene drawer
@property (nonatomic, assign, readonly) GLuint lightsUniformBlockIndex;
@property (nonatomic, assign, readonly) GLuint transformUniformBlockIndex;
@property (nonatomic, assign, readonly) GLuint alphaTestUniformBlockIndex;

@end
