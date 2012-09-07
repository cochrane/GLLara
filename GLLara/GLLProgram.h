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

@interface GLLProgram : NSObject

- (id)initWithDescriptor:(GLLShaderDescriptor *)descriptor resourceManager:(GLLResourceManager *)manager;

- (void)unload;

@property (nonatomic, copy, readonly) NSString *name;

@property (nonatomic, assign, readonly) GLuint programID;

// Uniforms set by mesh
@property (nonatomic, assign, readonly) GLint boneMatricesUniformLocation;
@property (nonatomic, assign, readonly) GLuint renderParametersUniformBlockIndex;

// Uniforms set by scene drawer
@property (nonatomic, assign, readonly) GLuint lightsUniformBlockIndex;
@property (nonatomic, assign, readonly) GLuint transformUniformBlockIndex;
@property (nonatomic, assign, readonly) GLuint alphaTestUniformBlockIndex;

@end
