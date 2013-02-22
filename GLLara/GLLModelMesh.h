//
//  GLLModelMesh.h
//  GLLara
//
//  Created by Torsten Kammer on 31.08.12.
//  Copyright (c) 2012 Torsten Kammer. All rights reserved.
//

#import <Foundation/Foundation.h>

@class GLLASCIIScanner;
@class GLLMeshSplitter;
@class GLLModel;
@class GLLShaderDescription;
@class TRInDataStream;

typedef enum GLLCullFaceMode
{
	GLLCullCounterClockWise,
	GLLCullClockWise,
	GLLCullNone
} GLLCullFaceMode;

/*!
 * @abstract Vertex and element data.
 * @discussion A GLLMesh stores a set of vertices that belong together, along with the necessary information for rendering it (especially the indices and the names of the textures used). In XNALara, it corresponds to a MeshDesc.
 */
@interface GLLModelMesh : NSObject

// For subclasses
- (id)initAsPartOfModel:(GLLModel *)model;

- (id)initFromStream:(TRInDataStream *)stream partOfModel:(GLLModel *)model error:(NSError *__autoreleasing*)error;
- (id)initFromScanner:(GLLASCIIScanner *)scanner partOfModel:(GLLModel *)model error:(NSError *__autoreleasing*)error;

@property (nonatomic, weak) GLLModel *model;

@property (nonatomic, copy) NSString *name;
@property (nonatomic, copy) NSString *displayName;
@property (nonatomic, retain) NSArray *textures;

@property (nonatomic, assign) NSUInteger meshIndex;

/*
 * Vertex buffer (format described below)
 */
@property (nonatomic, retain) NSData *vertexData;
@property (nonatomic, assign) NSUInteger countOfVertices;

/*
 * Description of vertex buffer.
 *
 * Position and normal are 3 floats
 * Color is 4 uint8_ts (r, g, b, a)
 * Any texcoord is two floats.
 * Any tangent is four floats (x, y, z, w)
 * Bone indices is 4 uint16_ts, and are indices in the boneIndices array
 * Bone weights is 4 floats.
 */
@property (nonatomic, assign, readonly) NSUInteger offsetForPosition;
@property (nonatomic, assign, readonly) NSUInteger offsetForNormal;
@property (nonatomic, assign, readonly) NSUInteger offsetForColor;
- (NSUInteger)offsetForTexCoordLayer:(NSUInteger)layer;
- (NSUInteger)offsetForTangentLayer:(NSUInteger)layer;
@property (nonatomic, assign, readonly) NSUInteger offsetForBoneIndices;
@property (nonatomic, assign, readonly) NSUInteger offsetForBoneWeights;
@property (nonatomic, assign, readonly) NSUInteger stride;

/*
 * Element buffer (format always uint32_ts arranged as triangles)
 */
@property (nonatomic, retain) NSData *elementData;
@property (nonatomic, assign) NSUInteger countOfElements;

/*
 * Bone indices. A mesh can use at most 59 bones, but a model can have much more than that. Each element of this array is an NSNumber index into the total number of bones the model has.
 */

/*
 * Other important properties.
 */
@property (nonatomic, assign) NSUInteger countOfUVLayers;
@property (nonatomic, assign, readonly) BOOL hasBoneWeights;
@property (nonatomic, readonly) BOOL hasTangents;
@property (nonatomic, copy, readonly) NSURL *baseURL;

/*
 * XNALara insists that some meshes need to be split; apparently only for cosmetic reasons. I shall oblige, but in a way that is not specific to exactly one thing, thank you very much. Note that this mesh keeps the bone indices of the original.
 */
- (GLLModelMesh *)partialMeshInBoxMin:(const float *)min max:(const float *)max name:(NSString *)name;
- (GLLModelMesh *)partialMeshFromSplitter:(GLLMeshSplitter *)splitter;

/*
 * Drawing information, gained through the model parameters. This information is not stored in the mesh file.
 */
@property (nonatomic, retain) GLLShaderDescription *shader;
@property (nonatomic, assign) BOOL usesAlphaBlending;
@property (nonatomic, copy) NSDictionary *renderParameterValues;

// -- For subclasses
// Calculates the tangents based on the texture coordinates, and fills them in the correct fields of the data, using the offsets and strides of the file
- (void)calculateTangents:(NSMutableData *)vertexData;

// Checks whether all the data is valid and can be used. Should be done before calculateTangents:!
- (BOOL)validateVertexData:(NSData *)vertexData indexData:(NSData *)indicesData error:(NSError *__autoreleasing*)error;

// Ensures that all bone weights are correct
- (NSData *)normalizeBoneWeightsInVertices:(NSData *)vertexData;

// Finalize loading. In particular, load render parameters.
- (void)finishLoading;



@property (nonatomic, assign, readonly) GLLCullFaceMode cullFaceMode;

// Export
- (NSString *)writeASCII;
- (NSData *)writeBinary;

@end
