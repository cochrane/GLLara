//
//  GLLVertexFormat.m
//  GLLara
//
//  Created by Torsten Kammer on 16.11.15.
//  Copyright (c) 2015 Torsten Kammer. All rights reserved.
//

#import "GLLVertexFormat.h"

#import "NSArray+Map.h"

@implementation GLLVertexAttribAccessor

- (instancetype)initWithAttrib:(enum GLLVertexAttrib)attrib layer:(NSUInteger) layer size:(enum GLLVertexAttribSize)size componentType:(enum GLLVertexAttribComponentType)type; {
    if (!(self = [super init])) {
        return nil;
    }
        
    NSAssert(type != GllVertexAttribComponentTypeInt2_10_10_10_Rev || size == GLLVertexAttribSizeVec4, @"2_10_10_10_Rev only allowed with Vec4");
    
    _attrib = attrib;
    _layer = layer;
    _size = size;
    _type = type;
    
    return self;
}

- (NSUInteger)hash
{
    return _attrib ^ _layer ^ _size ^ _type;
}

- (BOOL)isEqual:(id)object
{
    if (![object isKindOfClass:self.class])
        return NO;
    
    GLLVertexAttribAccessor *format = (GLLVertexAttribAccessor *) object;
    return format.attrib == self.attrib && format.layer == self.layer && format.size == self.size && format.type == self.type;
}

- (id)copy
{
    return self;
}

- (id)copyWithZone:(NSZone *)zone
{
    return self;
}

- (NSUInteger)baseSize {
    switch (self.type) {
        case GllVertexAttribComponentTypeByte:
        case GllVertexAttribComponentTypeUnsignedByte:
            return 1;
        case GllVertexAttribComponentTypeShort:
        case GllVertexAttribComponentTypeUnsignedShort:
        case GllVertexAttribComponentTypeHalfFloat:
            return 2;
        case GllVertexAttribComponentTypeFloat:
            return 4;
        case GllVertexAttribComponentTypeInt2_10_10_10_Rev:
            return 1;
        default:
            return 0;
    }
}

- (NSUInteger)numberOfElements {
    switch (self.size) {
        case GLLVertexAttribSizeScalar:
            return 1;
        case GLLVertexAttribSizeVec2:
            return 2;
        case GLLVertexAttribSizeVec3:
            return 3;
        case GLLVertexAttribSizeVec4:
        case GLLVertexAttribSizeMat2:
            return 4;
        case GLLVertexAttribSizeMat3:
            return 9;
        case GLLVertexAttribSizeMat4:
            return 16;
        default:
            return 0;
    }
}

- (NSUInteger)sizeInBytes {
    if (self.type == GllVertexAttribComponentTypeInt2_10_10_10_Rev) {
        return 4;
    }
    return self.baseSize * self.numberOfElements;
}

@end

@interface GLLVertexFormat()

- (NSUInteger)offsetForAttrib:(enum GLLVertexAttrib)attrib layer:(NSUInteger)layer;

@end

@implementation GLLVertexFormat

- (instancetype)initWithAttributes:(NSArray<GLLVertexAttribAccessor *>*)attributes countOfVertices:(NSUInteger)countOfVertices;
{
    if (!(self = [super init])) {
        return nil;
    }
    
    _attributes = [attributes copy];
    
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

- (instancetype)initWithBoneWeights:(BOOL)boneWeights tangents:(BOOL)tangents colorsAsFloats:(BOOL)floatColor countOfUVLayers:(NSUInteger)countOfUVLayers countOfVertices:(NSUInteger)countOfVertices;
{
    NSMutableArray *attributes = [NSMutableArray array];
    [attributes addObject:[[GLLVertexAttribAccessor alloc] initWithAttrib:GLLVertexAttribPosition layer:0 size:GLLVertexAttribSizeVec3 componentType:GllVertexAttribComponentTypeFloat]];
    [attributes addObject:[[GLLVertexAttribAccessor alloc] initWithAttrib:GLLVertexAttribNormal layer:0 size:GLLVertexAttribSizeVec3 componentType:GllVertexAttribComponentTypeFloat]];
    if (floatColor) {
        [attributes addObject:[[GLLVertexAttribAccessor alloc] initWithAttrib:GLLVertexAttribColor layer:0 size:GLLVertexAttribSizeVec4 componentType:GllVertexAttribComponentTypeFloat]];
    } else {
        [attributes addObject:[[GLLVertexAttribAccessor alloc] initWithAttrib:GLLVertexAttribColor layer:0 size:GLLVertexAttribSizeVec4 componentType:GllVertexAttribComponentTypeUnsignedByte]];
    }
    for (NSUInteger i = 0; i < countOfUVLayers; i++) {
        [attributes addObject:[[GLLVertexAttribAccessor alloc] initWithAttrib:GLLVertexAttribTexCoord0 layer:i size:GLLVertexAttribSizeVec2 componentType:GllVertexAttribComponentTypeFloat]];
    }
    if (tangents) {
        for (NSUInteger i = 0; i < countOfUVLayers; i++) {
            [attributes addObject:[[GLLVertexAttribAccessor alloc] initWithAttrib:GLLVertexAttribTangent0 layer:i size:GLLVertexAttribSizeVec4 componentType:GllVertexAttribComponentTypeFloat]];
        }
    }
    if (boneWeights) {
        [attributes addObject:[[GLLVertexAttribAccessor alloc] initWithAttrib:GLLVertexAttribBoneIndices layer:0 size:GLLVertexAttribSizeVec4 componentType:GllVertexAttribComponentTypeUnsignedShort]];
        [attributes addObject:[[GLLVertexAttribAccessor alloc] initWithAttrib:GLLVertexAttribBoneWeights layer:0 size:GLLVertexAttribSizeVec4 componentType:GllVertexAttribComponentTypeFloat]];
    }
    
    return [self initWithAttributes:attributes countOfVertices:countOfVertices];
}

- (NSUInteger)hash
{
    return _numElementBytes ^ [_attributes hash];
}

- (BOOL)isEqual:(id)object
{
    if (![object isKindOfClass:self.class])
        return NO;
    
    GLLVertexFormat *format = (GLLVertexFormat *) object;
    return format.numElementBytes == self.numElementBytes && [format.attributes isEqual:self.attributes];
}

- (GLLVertexAttribAccessor *)accessorForAttrib:(enum GLLVertexAttrib)attrib layer:(NSUInteger)layer; {
    return [self.attributes firstObjectMatching:^BOOL(GLLVertexAttribAccessor *accessor) {
        return accessor.attrib == attrib && accessor.layer == layer;
    }];
}

- (BOOL)hasBoneWeights {
    return [self accessorForAttrib:GLLVertexAttribBoneWeights layer:0] != nil;
}

- (BOOL)hasTangents {
    return [self accessorForAttrib:GLLVertexAttribTangent0 layer:0] != nil;
}

- (NSUInteger)countOfUVLayers {
    NSUInteger uvLayers = 0;
    for (GLLVertexAttribAccessor *accessor in _attributes) {
        if (accessor.attrib == GLLVertexAttribTexCoord0) {
            uvLayers += 1;
        }
    }
    return uvLayers;
}

- (NSUInteger)offsetForAttrib:(enum GLLVertexAttrib)attrib layer:(NSUInteger)layer; {
    NSUInteger offset = 0;
    for (GLLVertexAttribAccessor *accessor in self.attributes) {
        if (accessor.attrib == attrib && accessor.layer == layer) {
            return offset;
        } else {
            offset += accessor.sizeInBytes;
        }
    }
    return NSNotFound;
}

- (NSUInteger)offsetForPosition
{
    return [self offsetForAttrib:GLLVertexAttribPosition layer:0];
}
- (NSUInteger)offsetForNormal
{
    return [self offsetForAttrib:GLLVertexAttribNormal layer:0];
}
- (NSUInteger)offsetForColor
{
    return [self offsetForAttrib:GLLVertexAttribColor layer:0];
}
- (NSUInteger)offsetForTexCoordLayer:(NSUInteger)layer
{
    return [self offsetForAttrib:GLLVertexAttribTexCoord0 layer:layer];
}
- (NSUInteger)offsetForTangentLayer:(NSUInteger)layer
{
    return [self offsetForAttrib:GLLVertexAttribTangent0 layer:layer];
}
- (NSUInteger)offsetForBoneIndices
{
    return [self offsetForAttrib:GLLVertexAttribBoneIndices layer:0];
}
- (NSUInteger)offsetForBoneWeights
{
    return [self offsetForAttrib:GLLVertexAttribBoneWeights layer:0];
}
- (NSUInteger)stride
{
    NSUInteger stride = 0;
    for (GLLVertexAttribAccessor *accessor in self.attributes) {
        stride += accessor.sizeInBytes;
    }
    return stride;
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
