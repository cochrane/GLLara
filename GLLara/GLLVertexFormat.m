//
//  GLLVertexFormat.m
//  GLLara
//
//  Created by Torsten Kammer on 16.11.15.
//  Copyright (c) 2015 Torsten Kammer. All rights reserved.
//

#import "GLLVertexFormat.h"

@implementation GLLVertexFormat

- (instancetype)initWithBoneWeights:(BOOL)boneWeights tangents:(BOOL)tangents colorsAsFloats:(BOOL)floatColor countOfUVLayers:(NSUInteger)countOfUVLayers countOfVertices:(NSUInteger)countOfVertices;
{
    if (!(self = [super init])) {
        return nil;
    }
    
    _hasTangents = tangents;
    _hasBoneWeights = boneWeights;
    _colorIsFloat = floatColor;
    _countOfUVLayers = countOfUVLayers;
    if (countOfVertices < UINT8_MAX)
        _numElementBytes = 1;
    else if (countOfVertices < UINT16_MAX)
        _numElementBytes = 2;
    else if (countOfVertices < UINT32_MAX)
        _numElementBytes = 4;
    else
        [NSException raise:NSInvalidArgumentException format:@"%li vertices outside allowed range", countOfVertices];
    
    return self;
}

- (NSUInteger)hash
{
    return (_numElementBytes << 6) + ((_hasTangents != 0) << 4) + (_countOfUVLayers << 2) + (_hasBoneWeights != 0);
}

- (BOOL)isEqual:(id)object
{
    if (![object isKindOfClass:self.class])
        return NO;
    
    GLLVertexFormat *format = (GLLVertexFormat *) object;
    return format.countOfUVLayers == _countOfUVLayers && format.hasBoneWeights == _hasBoneWeights && format.hasTangents == _hasTangents && format.numElementBytes == _numElementBytes;
}

- (NSUInteger)colorSize {
    return self.colorIsFloat ? sizeof(float [4]) : sizeof(uint8_t [4]);
}

- (NSUInteger)offsetForPosition
{
    return 0;
}
- (NSUInteger)offsetForNormal
{
    return sizeof(float [3]);
}
- (NSUInteger)offsetForColor
{
    return sizeof(float [6]);
}
- (NSUInteger)offsetForTexCoordLayer:(NSUInteger)layer
{
    NSAssert(layer < self.countOfUVLayers, @"Asking for layer %lu but we only have %lu", layer, self.countOfUVLayers);
    
    return sizeof(float [6]) + self.colorSize + sizeof(float [2])*layer;
}
- (NSUInteger)offsetForTangentLayer:(NSUInteger)layer
{
    NSAssert(layer < self.countOfUVLayers, @"Asking for layer %lu but we only have %lu", layer, self.countOfUVLayers);
    
    return sizeof(float [6]) + self.colorSize + sizeof(float [2])*self.countOfUVLayers + sizeof(float [4])*layer;
}
- (NSUInteger)offsetForBoneIndices
{
    NSAssert(self.hasBoneWeights, @"Asking for offset for bone indices in mesh that doesn't have any.");
    
    return sizeof(float [6]) + self.colorSize + sizeof(float [2])*self.countOfUVLayers + (self.hasTangents ? sizeof(float[4])*self.countOfUVLayers : 0);
}
- (NSUInteger)offsetForBoneWeights
{
    NSAssert(self.hasBoneWeights, @"Asking for offset for bone indices in mesh that doesn't have any.");
    return sizeof(float [6]) + self.colorSize + sizeof(float [2])*self.countOfUVLayers + (self.hasTangents ? sizeof(float[4])*self.countOfUVLayers : 0) + sizeof(uint16_t [4]);
}
- (NSUInteger)stride
{
    return sizeof(float [6]) + self.colorSize + sizeof(float [2])*self.countOfUVLayers + (self.hasTangents ? sizeof(float[4])*self.countOfUVLayers : 0) + (self.hasBoneWeights ? (sizeof(uint16_t [4]) + sizeof(float [4])) : 0);
}

- (id)copy
{
    return self;
}

- (id)copyWithZone:(NSZone *)zone
{
    return self;
}

@end
