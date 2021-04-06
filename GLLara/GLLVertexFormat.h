//
//  GLLVertexFormat.h
//  GLLara
//
//  Created by Torsten Kammer on 01.09.12.
//  Copyright (c) 2012 Torsten Kammer. All rights reserved.
//

#ifndef GLLara_GLLVertexFormat_h
#define GLLara_GLLVertexFormat_h

#import <Foundation/Foundation.h>

/*!
 * @abstract Defines the indices for the different vertex attribute arrays.
 */
enum GLLVertexAttrib
{
	GLLVertexAttribPosition,
	GLLVertexAttribNormal,
	GLLVertexAttribColor,
	GLLVertexAttribBoneIndices,
	GLLVertexAttribBoneWeights,
	GLLVertexAttribTexCoord0,
	GLLVertexAttribTangent0
};

enum GLLVertexAttribSize {
    GLLVertexAttribSizeScalar,
    GLLVertexAttribSizeVec2,
    GLLVertexAttribSizeVec3,
    GLLVertexAttribSizeVec4,
    GLLVertexAttribSizeMat2,
    GLLVertexAttribSizeMat3,
    GLLVertexAttribSizeMat4
};

enum GLLVertexAttribComponentType {
    GllVertexAttribComponentTypeByte = 5120,
    GllVertexAttribComponentTypeUnsignedByte = 5121,
    GllVertexAttribComponentTypeShort = 5122,
    GllVertexAttribComponentTypeUnsignedShort = 5123,
    GllVertexAttribComponentTypeFloat = 5126,
    GllVertexAttribComponentTypeHalfFloat = 0x140B,
    GllVertexAttribComponentTypeInt2_10_10_10_Rev = 0x8D9F // Must be vec4
};

@interface GLLVertexAttribAccessor : NSObject<NSCopying>

- (instancetype)initWithAttrib:(enum GLLVertexAttrib)attrib layer:(NSUInteger) layer size:(enum GLLVertexAttribSize)size componentType:(enum GLLVertexAttribComponentType)type;

@property (nonatomic, readonly, assign) enum GLLVertexAttrib attrib;
@property (nonatomic, readonly, assign) NSUInteger layer;
@property (nonatomic, readonly, assign) enum GLLVertexAttribSize size;
@property (nonatomic, readonly, assign) enum GLLVertexAttribComponentType type;

@property (nonatomic, readonly, assign) NSUInteger baseSize;
@property (nonatomic, readonly, assign) NSUInteger numberOfElements;
@property (nonatomic, readonly, assign) NSUInteger sizeInBytes;

@end

@interface GLLVertexFormat : NSObject<NSCopying>

- (instancetype)initWithBoneWeights:(BOOL)boneWeights tangents:(BOOL)tangents colorsAsFloats:(BOOL)floatColors countOfUVLayers:(NSUInteger)countOfUVLayers countOfVertices:(NSUInteger)countOfVertices;

- (instancetype)initWithAttributes:(NSArray<GLLVertexAttribAccessor *>*)attributes countOfVertices:(NSUInteger)countOfVertices;

@property (nonatomic, readonly, copy) NSArray<GLLVertexAttribAccessor *>* attributes;

- (GLLVertexAttribAccessor *)accessorForAttrib:(enum GLLVertexAttrib)attrib layer:(NSUInteger)layer;

@property (nonatomic, readonly, assign) BOOL hasBoneWeights;
@property (nonatomic, readonly, assign) BOOL hasTangents;
@property (nonatomic, readonly, assign) NSUInteger countOfUVLayers;
// Number of bytes for storing an element. Only valid values are 1, 2 and 4
@property (nonatomic, readonly, assign) NSUInteger numElementBytes;

/*
 * Description of vertex buffer.
 *
 * Position and normal are 3 floats
 * Color is 4 uint8_ts (r, g, b, a), unless it's floats
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

@end

#endif
