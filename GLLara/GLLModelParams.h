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

@interface GLLMeshParams: NSObject

@property (nonatomic, readonly) NSArray<NSString *> *meshGroups;
@property (nonatomic, readonly) NSString *displayName;
@property (nonatomic, readonly) BOOL visible;
@property (nonatomic, readonly) NSArray<NSString *> *optionalPartNames;
@property (nonatomic, readonly) GLLShaderDescription *shader;
@property (nonatomic, readonly) BOOL transparent;
@property (nonatomic, readonly) NSDictionary<NSString *, id> *renderParameters;
@property (nonatomic, readonly) NSArray<GLLMeshSplitter *> *splitters;

@end

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

- (GLLMeshParams *)paramsForMesh:(NSString *)meshName;

/*
 * Camera targets
 */
@property (nonatomic, copy, readonly) NSArray<NSString *> *cameraTargets;
- (NSArray<NSString *> *)boneNamesForCameraTarget:(NSString *)cameraTarget;

/*
 * Rendering
 */
- (id)defaultValueForRenderParameter:(NSString *)renderParameter;
- (NSURL *)defaultValueForTexture:(NSString *)textureIdentifier;

- (GLLShaderDescription *)shaderNamed:(NSString *)name;
@property (nonatomic, readonly) NSArray<GLLShaderDescription *> *allShaders;

/*
 * Render parameter and texture descriptions
 */
- (GLLRenderParameterDescription *)descriptionForParameter:(NSString *)parameterName;
- (GLLTextureDescription *)descriptionForTexture:(NSString *)textureUniformName;

@end
