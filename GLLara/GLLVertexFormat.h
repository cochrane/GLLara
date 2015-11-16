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

@interface GLLVertexFormat : NSObject<NSCopying>

- (instancetype)initWithBoneWeights:(BOOL)boneWeights tangents:(BOOL)tangents countOfUVLayers:(NSUInteger)countOfUVLayers countOfVertices:(NSUInteger)countOfVertices;

@property (nonatomic, readonly, assign) BOOL hasBoneWeights;
@property (nonatomic, readonly, assign) BOOL hasTangents;
@property (nonatomic, readonly, assign) NSUInteger countOfUVLayers;
// Number of bytes for storing an element. Only valid values are 1, 2 and 4
@property (nonatomic, readonly, assign) NSUInteger numElementBytes;

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

@end

#endif
