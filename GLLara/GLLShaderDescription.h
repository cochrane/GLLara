//
//  GLLShaderDescription.h
//  GLLara
//
//  Created by Torsten Kammer on 05.09.12.
//  Copyright (c) 2012 Torsten Kammer. All rights reserved.
//

#import <Foundation/Foundation.h>

@class GLLModelParams;
@class GLLRenderParameterDescription;
@class GLLTextureDescription;

/*!
 * @abstract Description of a rendering method.
 * @discussion A rendering method always corresponds to one shader, but also
 * stores the inputs to this shader, in particular the render parameters
 * (model-specific uniforms) and textures it expects, and the render group
 * names to which this shader applies.
 */
@interface GLLShaderDescription : NSObject

- (id)initWithPlist:(NSDictionary *)plist name:(NSString *)name baseURL:(NSURL *)baseURL modelParameters:(GLLModelParams *)parameters;

@property (nonatomic, copy, readonly) NSString *name;
@property (nonatomic, copy, readonly) NSURL *baseURL;
@property (nonatomic, weak, readonly) GLLModelParams *parameters;

/*
 * Names of the shaders to be used.
 */
@property (nonatomic, copy, readonly) NSString *vertexName;
@property (nonatomic, copy, readonly) NSString *geometryName;
@property (nonatomic, copy, readonly) NSString *fragmentName;

/*
 * Names of uniforms, in the order that they are specified by models.
 * For each mesh, textures are just specified one after the other, with no information what those textures do. Similarly, with the generic_item format, the settings for the uniforms are specified one after the other, with no information what they do. These arrays give the uniform name for the corresponding index.
 */
@property (nonatomic, copy, readonly) NSArray *parameterUniformNames;
@property (nonatomic, copy, readonly) NSArray *textureUniformNames;

/*
 * Uniforms that are not specified by models.
 */
@property (nonatomic, copy, readonly) NSArray *additionalUniformNames;

@property (nonatomic, copy, readonly) NSArray *allUniformNames;

/*
 * Mesh groups for which this shader should be used.
 */
@property (nonatomic, copy, readonly) NSSet *solidMeshGroups;
@property (nonatomic, copy, readonly) NSSet *alphaMeshGroups;

/*
 * Unique identifier for this shader. Used to put the shader in a collection.
 */
@property (nonatomic, retain, readonly) id<NSCopying> programIdentifier;

/*
 * Human-readable name for UI
 */
@property (nonatomic, copy, readonly) NSString *localizedName;

/*
 * Description for a parameter, to set up an UI around it.
 */
- (GLLRenderParameterDescription *)descriptionForParameter:(NSString *)parameterName;
- (GLLTextureDescription *)descriptionForTexture:(NSString *)textureUniformName;

@end
