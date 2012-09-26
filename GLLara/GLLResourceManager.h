//
//  GLLResourceManager.h
//  GLLara
//
//  Created by Torsten Kammer on 04.09.12.
//  Copyright (c) 2012 Torsten Kammer. All rights reserved.
//

#import <AppKit/NSOpenGL.h>
#import <Foundation/Foundation.h>

#import <OpenGL/gltypes.h>

@class GLLProgram;
@class GLLModelProgram;
@class GLLTexture;
@class GLLModel;
@class GLLModelDrawer;
@class GLLShader;
@class GLLShaderDescription;

/*
 * Stores all resources for the program.
 * The resources are stored in their own OpenGL Context. Every GLLView in an app will share its context with this one. As a result, they will be available in all SceneDrawers.
 * It will use its own context for all loading, but at the end of every public method (after the initializer), the previous context will be set again.
 * Important! This relies on Vertex Array Objects being shared. This is not standard, but is apparently what the APPLE_container_object_shareable extension does (always available on Mac OS X, according to https://developer.apple.com/graphicsimaging/opengl/capabilities/ ). At least it works. There is no enabling or disabling this extensions.
 * Second important thing! The uniform values for shaders are shared. This is not a big problem since most shaders don't use uniforms at all, but uniform blocks (sharing their bindings is actually a good thing). But this means that if you try to use multithreading, uniforms will end up with values you didn't expect, so don't do it.
 */
@interface GLLResourceManager : NSObject

+ (id)sharedResourceManager;

@property (nonatomic, readonly) NSOpenGLContext *openGLContext;

- (GLLModelDrawer *)drawerForModel:(GLLModel *)model error:(NSError *__autoreleasing*)error;
- (GLLModelProgram *)programForDescriptor:(GLLShaderDescription *)descriptor error:(NSError *__autoreleasing*)error;
- (GLLTexture *)textureForURL:(NSURL *)textureURL error:(NSError *__autoreleasing*)error;
- (GLLShader *)shaderForName:(NSString *)shaderName type:(GLenum)type baseURL:(NSURL *)baseURL error:(NSError *__autoreleasing*)error;

// Shared programs and buffers that everyone needs sometime
@property (nonatomic) GLLProgram *squareProgram;
@property (nonatomic) GLuint squareVertexArray;

@property (nonatomic) GLuint alphaTestDisabledBuffer;
@property (nonatomic) GLuint alphaTestPassGreaterBuffer;
@property (nonatomic) GLuint alphaTestPassLessBuffer;

@end
