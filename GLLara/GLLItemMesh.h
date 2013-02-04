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

/*!
 * @abstract Stores per-mesh data in the document.
 * @discussion This class is mainly a container for the different render values
 * that affect a mesh and that need to be stored.
 */
@interface GLLItemMesh : NSManagedObject

// Core data
@property (nonatomic) BOOL isVisible;
@property (nonatomic, retain) GLLItem *item;
@property (nonatomic) int16_t cullFaceMode;
@property (nonatomic, retain) NSSet *renderParameters;
@property (nonatomic, retain) NSSet *textures;

// Derived
@property (nonatomic, readonly) NSUInteger meshIndex;
@property (nonatomic, retain, readonly) GLLModelMesh *mesh;
@property (nonatomic, readonly, copy) NSString *displayName;

// This key is just for observing. Don't try to actually read it.
@property (nonatomic, retain) id renderSettings;

- (GLLRenderParameter *)renderParameterWithName:(NSString *)parameterName;
- (GLLItemMeshTexture *)textureWithIdentifier:(NSString *)textureIdentifier;

@end

@interface GLLItemMesh (CoreDataGeneratedAccessors)

- (void)addRenderParametersObject:(GLLRenderParameter *)value;
- (void)removeRenderParametersObject:(GLLRenderParameter *)value;
- (void)addRenderParameters:(NSSet *)values;
- (void)removeRenderParameters:(NSSet *)values;

- (void)addTexturesObject:(GLLRenderParameter *)value;
- (void)removeTexturesObject:(GLLRenderParameter *)value;
- (void)addTextures:(NSSet *)values;
- (void)removeTextures:(NSSet *)values;

@end
