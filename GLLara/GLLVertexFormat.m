//
//  GLLVertexFormat.m
//  GLLara
//
//  Created by Torsten Kammer on 16.11.15.
//  Copyright (c) 2015 Torsten Kammer. All rights reserved.
//

#import "GLLVertexFormat.h"

#import "NSArray+Map.h"

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
