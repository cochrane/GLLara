//
//  GLLModelMesh.h
//  GLLara
//
//  Created by Torsten Kammer on 31.08.12.
//  Copyright (c) 2012 Torsten Kammer. All rights reserved.
//

#import <Foundation/Foundation.h>

#import "GLLVertexAttrib.h"

@class GLLASCIIScanner;
@class GLLMeshSplitter;
@class GLLModel;
@class GLLShaderData;
@class GLLTextureAssignment;
@class GLLVertexAttribAccessor;
@class GLLVertexAttribAccessorSet;
@class GLLVertexFormat;
@class TRInDataStream;
@class NSColor;

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
@property (nonatomic, retain) NSDictionary<NSString *, GLLTextureAssignment *> *textures;
@property (nonatomic, assign, readonly) BOOL initiallyVisible;
@property (nonatomic, copy, readonly) NSArray<NSString *>* optionalPartNames;

@property (nonatomic, assign, readonly) NSUInteger meshIndex;

/*
 * Vertex buffer
 */
@property (nonatomic, assign) NSUInteger countOfVertices;
@property (nonatomic, retain) GLLVertexAttribAccessorSet* vertexDataAccessors;

@property (nonatomic, copy) GLLVertexFormat *vertexFormat;

/*
 * Element buffer (format always uint32_ts arranged as triangles)
 */
@property (nonatomic, retain) NSData *elementData;
@property (nonatomic, assign) GLLVertexAttribComponentType elementComponentType;
@property (nonatomic, assign) NSUInteger countOfElements;

// Returns the element fo the index. If there is no element buffer (i.e. directly), returns its index
- (NSUInteger)elementAt:(NSUInteger)index;
// Returns the count of indices you can use with elementAt - that is either the number of elements, if there is an element buffer, or the number of vertices if drawing directly without one
@property (nonatomic, assign, readonly) NSUInteger countOfUsedElements;

/*
 * Bone indices. A mesh can use at most 59 bones, but a model can have much more than that. Each element of this array is an NSNumber index into the total number of bones the model has.
 */

/*
 * Other important properties.
 */
@property (nonatomic, assign) NSUInteger countOfUVLayers;
@property (nonatomic, assign, readonly) BOOL hasBoneWeights;
@property (nonatomic, readonly) BOOL hasTangentsInFile;
@property (nonatomic, readonly) BOOL hasV4ExtraBytes;
@property (nonatomic, readonly) BOOL colorsAreFloats;
@property (nonatomic, copy, readonly) NSURL *baseURL;

/*
 * XNALara insists that some meshes need to be split; apparently only for cosmetic reasons. I shall oblige, but in a way that is not specific to exactly one thing, thank you very much. Note that this mesh keeps the bone indices of the original.
 */
- (GLLModelMesh *)partialMeshFromSplitter:(GLLMeshSplitter *)splitter;

/*
 * Drawing information, gained through the model parameters. This information is not stored in the mesh file.
 */
@property (nonatomic, retain) GLLShaderData *shader;
@property (nonatomic, assign) BOOL usesAlphaBlending;
@property (nonatomic, copy) NSDictionary<NSString *, id> *renderParameterValues;

// -- For subclasses
// Calculates the tangents based on the texture coordinates, and fills them in the correct fields of the data, using the offsets and strides of the file
- (GLLVertexAttribAccessorSet *)calculateTangents:(GLLVertexAttribAccessorSet *)fileVertexData;

// Checks whether all the data is valid and can be used. Should be done before calculateTangents:!
- (BOOL)validateVertexData:(GLLVertexAttribAccessorSet *)vertices indexData:(NSData *)indexData error:(NSError *__autoreleasing*)error;



@property (nonatomic, assign, readonly) GLLCullFaceMode cullFaceMode;

// Export
- (NSString *)writeASCIIWithName:(NSString *)name texture:(NSArray *)textures __attribute__((nonnull(1,2)));
- (NSData *)writeBinaryWithName:(NSString *)name texture:(NSArray *)textures __attribute__((nonnull(1,2)));

@end
