//
//  GLLResourceManager.h
//  GLLara
//
//  Created by Torsten Kammer on 04.09.12.
//  Copyright (c) 2012 Torsten Kammer. All rights reserved.
//

#import <Foundation/Foundation.h>

#import <OpenGL/gltypes.h>

@class GLLProgram;
@class GLLTexture;
@class GLLModel;
@class GLLModelDrawer;
@class GLLShader;
@class GLLShaderDescriptor;

@interface GLLResourceManager : NSObject

- (GLLModelDrawer *)drawerForModel:(GLLModel *)model error:(NSError *__autoreleasing*)error;
- (GLLProgram *)programForDescriptor:(GLLShaderDescriptor *)descriptor error:(NSError *__autoreleasing*)error;
- (GLLTexture *)textureForName:(NSString *)textureName baseURL:(NSURL *)baseURL;
- (GLLShader *)shaderForName:(NSString *)shaderName type:(GLenum)type baseURL:(NSURL *)baseURL error:(NSError *__autoreleasing*)error;

@property (nonatomic, copy, readonly) NSArray *alLLoadedPrograms;

- (void)unload;

@end
