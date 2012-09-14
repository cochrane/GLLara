//
//  GLLProgram.h
//  
//
//  Created by Torsten Kammer on 14.09.12.
//
//

#import <Foundation/Foundation.h>
#import <OpenGL/gltypes.h>

@class GLLResourceManager;
@class GLLShader;

@interface GLLProgram : NSObject

- (id)initWithName:(NSString *)name fragmentShaderName:(NSString *)fragmentName geometryShaderName:(NSString *)geometryName vertexShaderName:(NSString *)vertexName baseURL:(NSURL *)base resourceManager:(GLLResourceManager *)manager error:(NSError *__autoreleasing*)error;
- (id)initWithName:(NSString *)name fragmentShader:(GLLShader *)fragment geometryShader:(GLLShader *)geometry vertexShader:(GLLShader *)vertex error:(NSError *__autoreleasing*)error;

- (void)bindAttributeLocations;

@property (nonatomic, copy, readonly) NSString *name;

@property (nonatomic, assign, readonly) GLuint programID;

- (void)unload;

@end
