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
@class GLLShaderDescriptor;
@class GLLResourceManager;

/*!
 * @abstract A GLSL program, used by the default rendering path.
 * @discussion This class specifically sets up the buffers, binds the textures to the texture units, does linking and so on. It is written specifically for the model shaders. Other special effects shaders will need a different class, which is yet to be written (there's a good chance this class will inherit from it).
 */
@interface GLLProgram : NSObject

- (id)initWithDescriptor:(GLLShaderDescriptor *)descriptor resourceManager:(GLLResourceManager *)manager error:(NSError *__autoreleasing*)error;

- (void)unload;

@property (nonatomic, copy, readonly) NSString *name;

@property (nonatomic, assign, readonly) GLuint programID;

// Uniforms set by model
@property (nonatomic, assign, readonly) GLuint boneMatricesUniformBlockIndex;

// Uniforms set by mesh
@property (nonatomic, assign, readonly) GLuint renderParametersUniformBlockIndex;

// Uniforms set by scene drawer
@property (nonatomic, assign, readonly) GLuint lightsUniformBlockIndex;
@property (nonatomic, assign, readonly) GLuint transformUniformBlockIndex;
@property (nonatomic, assign, readonly) GLuint alphaTestUniformBlockIndex;

@end
