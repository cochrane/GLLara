//
//  GLLVertexFormat.m
//  GLLara
//
//  Created by Torsten Kammer on 16.11.15.
//  Copyright (c) 2015 Torsten Kammer. All rights reserved.
//

#import "GLLVertexFormat.h"

#import "NSArray+Map.h"

@interface GLLVertexFormat()

- (NSUInteger)offsetForAttrib:(enum GLLVertexAttribSemantic)attrib layer:(NSUInteger)layer;

@end

@implementation GLLVertexFormat

- (instancetype)initWithAttributes:(NSArray<GLLVertexAttrib *>*)attributes countOfVertices:(NSUInteger)countOfVertices;
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
    NSMutableArray<GLLVertexAttrib *> *attributes = [NSMutableArray array];
    [attributes addObject:[[GLLVertexAttrib alloc] initWithSemantic:GLLVertexAttribPosition layer:0 size:GLLVertexAttribSizeVec3 componentType:GllVertexAttribComponentTypeFloat dataBuffer:nil offset:0]];
    [attributes addObject:[[GLLVertexAttrib alloc] initWithSemantic:GLLVertexAttribNormal layer:0 size:GLLVertexAttribSizeVec3 componentType:GllVertexAttribComponentTypeFloat dataBuffer:nil offset:attributes.lastObject.sizeInBytes + attributes.lastObject.dataOffset]];
    if (floatColor) {
        [attributes addObject:[[GLLVertexAttrib alloc] initWithSemantic:GLLVertexAttribColor layer:0 size:GLLVertexAttribSizeVec4 componentType:GllVertexAttribComponentTypeFloat dataBuffer:nil offset:attributes.lastObject.sizeInBytes + attributes.lastObject.dataOffset]];
    } else {
        [attributes addObject:[[GLLVertexAttrib alloc] initWithSemantic:GLLVertexAttribColor layer:0 size:GLLVertexAttribSizeVec4 componentType:GllVertexAttribComponentTypeUnsignedByte dataBuffer:nil offset:attributes.lastObject.sizeInBytes + attributes.lastObject.dataOffset]];
    }
    for (NSUInteger i = 0; i < countOfUVLayers; i++) {
        [attributes addObject:[[GLLVertexAttrib alloc] initWithSemantic:GLLVertexAttribTexCoord0 layer:i size:GLLVertexAttribSizeVec2 componentType:GllVertexAttribComponentTypeFloat dataBuffer:nil offset:attributes.lastObject.sizeInBytes + attributes.lastObject.dataOffset]];
    }
    if (tangents) {
        for (NSUInteger i = 0; i < countOfUVLayers; i++) {
            [attributes addObject:[[GLLVertexAttrib alloc] initWithSemantic:GLLVertexAttribTangent0 layer:i size:GLLVertexAttribSizeVec4 componentType:GllVertexAttribComponentTypeFloat dataBuffer:nil offset:attributes.lastObject.sizeInBytes + attributes.lastObject.dataOffset]];
        }
    }
    if (boneWeights) {
        [attributes addObject:[[GLLVertexAttrib alloc] initWithSemantic:GLLVertexAttribBoneIndices layer:0 size:GLLVertexAttribSizeVec4 componentType:GllVertexAttribComponentTypeUnsignedShort dataBuffer:nil offset:attributes.lastObject.sizeInBytes + attributes.lastObject.dataOffset]];
        [attributes addObject:[[GLLVertexAttrib alloc] initWithSemantic:GLLVertexAttribBoneWeights layer:0 size:GLLVertexAttribSizeVec4 componentType:GllVertexAttribComponentTypeFloat dataBuffer:nil offset:attributes.lastObject.sizeInBytes + attributes.lastObject.dataOffset]];
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

- (GLLVertexAttrib *)attribForSemantic:(enum GLLVertexAttribSemantic)semantic layer:(NSUInteger)layer; {
    return [self.attributes firstObjectMatching:^BOOL(GLLVertexAttrib *attribute) {
        return attribute.semantic == semantic && attribute.layer == layer;
    }];
}

- (BOOL)hasBoneWeights {
    return [self attribForSemantic:GLLVertexAttribBoneWeights layer:0] != nil;
}

- (BOOL)hasTangents {
    return [self attribForSemantic:GLLVertexAttribTangent0 layer:0] != nil;
}

- (NSUInteger)countOfUVLayers {
    NSUInteger uvLayers = 0;
    for (GLLVertexAttrib *attribute in _attributes) {
        if (attribute.semantic == GLLVertexAttribTexCoord0) {
            uvLayers += 1;
        }
    }
    return uvLayers;
}

- (NSUInteger)offsetForAttrib:(enum GLLVertexAttribSemantic)attrib layer:(NSUInteger)layer; {
    return [self attribForSemantic:attrib layer:layer].dataOffset;
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
    for (GLLVertexAttrib *attribute in self.attributes) {
        stride += attribute.sizeInBytes;
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
