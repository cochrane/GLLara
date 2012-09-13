//
//  GLLModelHardcodedParams.h
//  GLLara
//
//  Created by Torsten Kammer on 01.09.12.
//  Copyright (c) 2012 Torsten Kammer. All rights reserved.
//

#import <Foundation/Foundation.h>

@class GLLModel;
@class GLLRenderParameterDescription;
@class GLLShaderDescription;

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
- (NSArray *)meshGroupsForMesh:(NSString *)meshName;

/*
 * Camera targets
 */
@property (nonatomic, copy, readonly) NSArray *cameraTargets;
- (NSArray *)boneNamesForCameraTarget:(NSString *)cameraTarget;

/*
 * Rendering
 */
- (NSString *)renderableMeshGroupForMesh:(NSString *)mesh;
- (void)getShader:(GLLShaderDescription *__autoreleasing *)shader alpha:(BOOL *)shaderIsAlpha forMeshGroup:(NSString *)meshGroup;

- (void)getShader:(GLLShaderDescription *__autoreleasing *)shader alpha:(BOOL *)shaderIsAlpha forMesh:(NSString *)mesh;
- (NSDictionary *)renderParametersForMesh:(NSString *)mesh;

- (GLLShaderDescription *)shaderNamed:(NSString *)name;

/*
 * Render parameter descriptions
 */
- (GLLRenderParameterDescription *)descriptionForParameter:(NSString *)parameterName;

/*
 * Splitting up objects
 */
@property (nonatomic, copy, readonly) NSArray *meshesToSplit;
- (NSArray *)meshSplittersForMesh:(NSString *)mesh;

@end
