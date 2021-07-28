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

/*!
 * @abstract A loaded GLSL program.
 * @discussion A program consists of several shaders, and the bound attribute
 * locations. This class is abstract. Actual programs either use GLLModelProgram,
 * which sets the bindings for standard models, or a custom subclass setting
 * the bindings for that.
 */
@interface GLLProgram : NSObject

- (id)initWithFragmentShaderName:(NSString *)fragmentName geometryShaderName:(NSString *)geometryName vertexShaderName:(NSString *)vertexName additionalDefines:(NSDictionary *)additionalDefines usedTexCoords:(NSIndexSet *)texCoords resourceManager:(GLLResourceManager *)manager error:(NSError *__autoreleasing*)error;
- (id)initWithFragmentShader:(GLLShader *)fragment geometryShader:(GLLShader *)geometry vertexShader:(GLLShader *)vertex error:(NSError *__autoreleasing*)error;

- (void)bindAttributeLocations;

@property (nonatomic, assign, readonly) GLuint programID;

- (void)unload;

// Get uniform offset. Internally cached. Returns < 0 if not found.
- (NSInteger)offsetForUniform:(NSString *)uniformName;

// Get uniform offset in block. Returns < 0 if not found.
- (NSInteger)offsetForUniform:(NSString *)uniformName inBlock:(NSString *)blockName;

@end
