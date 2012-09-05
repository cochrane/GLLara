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

- (GLLModelDrawer *)drawerForModel:(GLLModel *)model;
- (GLLProgram *)programForDescriptor:(GLLShaderDescriptor *)descriptor;
- (GLLTexture *)textureForName:(NSString *)textureName baseURL:(NSURL *)baseURL;
- (GLLShader *)shaderForName:(NSString *)shaderName type:(GLenum)type baseURL:(NSURL *)baseURL;

@property (nonatomic, copy, readonly) NSArray *alLLoadedPrograms;

@end
