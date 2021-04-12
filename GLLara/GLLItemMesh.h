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
@class GLLShaderDescription;

/*!
 * @abstract Stores per-mesh data in the document.
 * @discussion This class is mainly a container for the different render values
 * that affect a mesh and that need to be stored.
 */
@interface GLLItemMesh : NSManagedObject

// Core data
@property (nonatomic) BOOL isCustomBlending;
@property (nonatomic) BOOL isBlended;
@property (nonatomic) BOOL isVisible;
@property (nonatomic, retain) GLLItem *item;
@property (nonatomic) int16_t cullFaceMode;
@property (nonatomic, retain) NSSet<GLLRenderParameter *> *renderParameters;
@property (nonatomic, copy) NSString *shaderName;
@property (nonatomic, copy) NSString *displayName;
@property (nonatomic, retain) NSSet<GLLItemMeshTexture *> *textures;

// Called by the Item; fills the various values correctly
- (void)prepareGraphicsData;

// Derived
@property (nonatomic, readonly) NSUInteger meshIndex;
@property (nonatomic, retain, readonly) GLLModelMesh *mesh;
@property (nonatomic) GLLShaderDescription *shader;

@property (nonatomic) BOOL isUsingBlending;

- (GLLRenderParameter *)renderParameterWithName:(NSString *)parameterName;
- (GLLItemMeshTexture *)textureWithIdentifier:(NSString *)textureIdentifier;

@property (nonatomic, readonly) NSArray<GLLShaderDescription *> *possibleShaderDescriptions;

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
