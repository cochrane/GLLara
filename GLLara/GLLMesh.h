//
//  GLLMesh.h
//  GLLara
//
//  Created by Torsten Kammer on 31.08.12.
//  Copyright (c) 2012 Torsten Kammer. All rights reserved.
//

#import <Foundation/Foundation.h>

@class GLLASCIIScanner;
@class GLLMeshSplitter;
@class GLLModel;
@class GLLShaderDescriptor;
@class TRInDataStream;

/*!
 * @abstract Vertex and element data.
 * @discussion A GLLMesh stores a set of vertices that belong together, along with the necessary information for rendering it (especially the indices and the names of the textures used). In XNALara, it corresponds to a MeshDesc.
 */
@interface GLLMesh : NSObject

- (id)initFromStream:(TRInDataStream *)stream partOfModel:(GLLModel *)model;
- (id)initFromScanner:(GLLASCIIScanner *)scanner partOfModel:(GLLModel *)model;

@property (nonatomic, weak, readonly) GLLModel *model;

@property (nonatomic, copy, readonly) NSString *name;
@property (nonatomic, retain, readonly) NSArray *textures;

@property (nonatomic, assign, readonly) NSUInteger meshIndex;

/*
 * Vertex buffer (format described below)
 */
@property (nonatomic, retain, readonly) NSData *vertexData;
@property (nonatomic, assign, readonly) NSUInteger countOfVertices;

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
@property (nonatomic, retain, readonly) NSData *elementData;
@property (nonatomic, assign, readonly) NSUInteger countOfElements;

/*
 * Bone indices. A mesh can use at most 59 bones, but a model can have much more than that. Each element of this array is an NSNumber index into the total number of bones the model has.
 */
@property (nonatomic, copy, readonly) NSArray *boneIndices;

/*
 * Other important properties.
 */
@property (nonatomic, assign, readonly) NSUInteger countOfUVLayers;
@property (nonatomic, assign, readonly) BOOL hasBoneWeights;
@property (nonatomic, copy, readonly) NSURL *baseURL;

/*
 * XNALara insists that some meshes need to be split; apparently only for cosmetic reasons. I shall oblige, but in a way that is not specific to exactly one thing, thank you very much. Note that this mesh keeps the bone indices of the original.
 */
- (GLLMesh *)partialMeshInBoxMin:(const float *)min max:(const float *)max name:(NSString *)name;
- (GLLMesh *)partialMeshFromSplitter:(GLLMeshSplitter *)splitter;

/*
 * Drawing information, gained through the model parameters. This information is not stored in the mesh file.
 */
@property (nonatomic, copy, readonly) GLLShaderDescriptor *shader;
@property (nonatomic, assign, readonly) BOOL isAlphaPiece;
@property (nonatomic, copy, readonly) NSDictionary *renderParameters;

@end
