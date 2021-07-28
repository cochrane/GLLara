//
//  GLLItemMesh.h
//  GLLara
//
//  Created by Torsten Kammer on 05.09.12.
//  Copyright (c) 2012 Torsten Kammer. All rights reserved.
//

#import <CoreData/CoreData.h>
#import <Foundation/Foundation.h>

@class GLLItem;
@class GLLItemMeshTexture;
@class GLLModelMesh;
@class GLLRenderParameter;
@class GLLShaderData;

/*!
 * @abstract Stores per-mesh data in the document.
 * @discussion This class is mainly a container for the different render values
 * that affect a mesh and that need to be stored.
 */
@interface GLLItemMesh : NSManagedObject

/*!
 * Called by the Item when first creating the thing; sets the initial values for
 * everything. Functionally this is the constructor, but with CoreData being
 * what it is, we have to do it this way.
 */
- (void)prepareWithItem:(GLLItem *)item;

// Core data
@property (nonatomic) BOOL isCustomBlending;
@property (nonatomic) BOOL isBlended;
@property (nonatomic) BOOL isVisible;
@property (nonatomic, retain) GLLItem *item;
@property (nonatomic) int16_t cullFaceMode;
@property (nonatomic, retain) NSSet<GLLRenderParameter *> *renderParameters;
@property (nonatomic, copy) NSString *shaderBase;
@property (nonatomic, copy) NSString *displayName;
@property (nonatomic, retain) NSSet<GLLItemMeshTexture *> *textures;

// Derived
@property (nonatomic, readonly) NSUInteger meshIndex;
@property (nonatomic, retain, readonly) GLLModelMesh *mesh;
- (void)setIncluded:(BOOL)included forShaderModule:(NSString *)module;
- (BOOL)isShaderModuleIncluded:(NSString *)module;
@property (nonatomic, copy, readonly) NSSet<NSString *> *shaderModules;

// Local
@property (nonatomic, retain, readonly) GLLShaderData *shader;

// Called only internally and from child objects, in case some setting changed that requires a shader recompile
- (void)updateShader;

@property (nonatomic) BOOL isUsingBlending;

- (GLLRenderParameter *)renderParameterWithName:(NSString *)parameterName;
- (GLLItemMeshTexture *)textureWithIdentifier:(NSString *)textureIdentifier;

@end

@interface GLLItemMesh (CoreDataGeneratedAccessors)

- (void)addRenderParametersObject:(GLLRenderParameter *)value;
- (void)removeRenderParametersObject:(GLLRenderParameter *)value;
- (void)addRenderParameters:(NSSet<GLLRenderParameter *> *)values;
- (void)removeRenderParameters:(NSSet<GLLRenderParameter *> *)values;

- (void)addTexturesObject:(GLLItemMeshTexture *)value;
- (void)removeTexturesObject:(GLLItemMeshTexture *)value;
- (void)addTextures:(NSSet<GLLItemMeshTexture *> *)values;
- (void)removeTextures:(NSSet<GLLItemMeshTexture *> *)values;

@end
