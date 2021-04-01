//
//  GLLModelHardcodedParams.h
//  GLLara
//
//  Created by Torsten Kammer on 01.09.12.
//  Copyright (c) 2012 Torsten Kammer. All rights reserved.
//

#import <Foundation/Foundation.h>

@class GLLMeshSplitter;
@class GLLModel;
@class GLLRenderParameterDescription;
@class GLLShaderDescription;
@class GLLTextureDescription;

/*!
 * @abstract Encapsulates all the data that is hardcoded into XNALara and stores it in a single place.
 * @discussion Holy fucking shit. XNALara consists basically only of hardcoded values for every damn object you can import. And it's not just hardcoded in one place; there's the item subclasses, but the renderer also contains an awful lot of specific information. That sucks.
 
 * The goal of this class is to take all that information and put it into separate configuration files, where all this shit can be managed in a simple, central location.
 */
@interface GLLModelParams : NSObject

+ (id)parametersForModel:(GLLModel *)model error:(NSError *__autoreleasing*)error;
+ (id)parametersForName:(NSString *)name error:(NSError *__autoreleasing*)error;

- (id)initWithPlist:(NSDictionary *)propertyList error:(NSError *__autoreleasing*)error;

// Generic item format
- (id)initWithModel:(GLLModel *)aModel error:(NSError *__autoreleasing*)error;

@property (nonatomic, copy, readonly) NSString *modelName;
@property (nonatomic, copy, readonly) GLLModelParams *base;

/*
 * Organization into groups
 */
- (NSArray<NSString *> *)meshGroupsForMesh:(NSString *)meshName;

/*
 * Camera targets
 */
@property (nonatomic, copy, readonly) NSArray<NSString *> *cameraTargets;
- (NSArray<NSString *> *)boneNamesForCameraTarget:(NSString *)cameraTarget;

/*
 * Mesh name
 */
- (NSString *)displayNameForMesh:(NSString *)mesh;
// Whether this mesh is visible on load. Relevant for optional items
- (BOOL)initiallyVisibleForMesh:(NSString *)mesh;
// The names of optional item groups the mesh belongs to, hierarchically.
// If none, empty array. If there is no grouping, the result is a string with
// just one element.
- (NSArray<NSString *> *)optionalPartNamesForMesh:(NSString *)mesh;

/*
 * Rendering
 */
- (NSString *)renderableMeshGroupForMesh:(NSString *)mesh;
- (void)getShader:(GLLShaderDescription *__autoreleasing *)shader alpha:(BOOL *)shaderIsAlpha forMeshGroup:(NSString *)meshGroup;

- (void)getShader:(GLLShaderDescription *__autoreleasing *)shader alpha:(BOOL *)shaderIsAlpha forMesh:(NSString *)mesh;
- (NSDictionary<NSString *, id> *)renderParametersForMesh:(NSString *)mesh;

- (id)defaultValueForRenderParameter:(NSString *)renderParameter;
- (NSURL *)defaultValueForTexture:(NSString *)textureIdentifier;

- (GLLShaderDescription *)shaderNamed:(NSString *)name;
@property (nonatomic, readonly) NSArray<GLLShaderDescription *> *allShaders;

/*
 * Render parameter and texture descriptions
 */
- (GLLRenderParameterDescription *)descriptionForParameter:(NSString *)parameterName;
- (GLLTextureDescription *)descriptionForTexture:(NSString *)textureUniformName;

/*
 * Splitting up objects
 */
@property (nonatomic, copy, readonly) NSArray<NSString *> *meshesToSplit;
- (NSArray<GLLMeshSplitter *> *)meshSplittersForMesh:(NSString *)mesh;

@end
