//
//  GLLVertexAttribAccessor.m
//  GLLara
//
//  Created by Torsten Kammer on 06.04.21.
//  Copyright © 2021 Torsten Kammer. All rights reserved.
//

#import "GLLVertexAttrib.h"

@interface GLLVertexAttrib()

@property (nonatomic, readonly, assign) NSUInteger baseSize;

@end

@implementation GLLVertexAttrib

- (instancetype)initWithSemantic:(enum GLLVertexAttribSemantic)attrib layer:(NSUInteger) layer size:(enum GLLVertexAttribSize)size componentType:(enum GLLVertexAttribComponentType)type;
{
    if (!(self = [super init])) {
        return nil;
    }
        
    NSAssert(type != GLLVertexAttribComponentTypeInt2_10_10_10_Rev || size == GLLVertexAttribSizeVec4, @"2_10_10_10_Rev only allowed with Vec4");
    
    _semantic = attrib;
    _layer = layer;
    _size = size;
    _type = type;
    
    return self;
}

- (NSUInteger)hash
{
    return _semantic ^ _layer ^ _size ^ _type;
}

- (BOOL)isEqualFormat:(GLLVertexAttrib *)format
{
    return format.semantic == self.semantic && format.layer == self.layer && format.size == self.size && format.type == self.type;
}

- (BOOL)isEqual:(id)object
{
    if (![object isKindOfClass:self.class])
        return NO;
    
    GLLVertexAttrib *format = (GLLVertexAttrib *) object;
    return format.semantic == self.semantic && format.layer == self.layer && format.size == self.size && format.type == self.type;
}

- (id)copy
{
    return self;
}

- (id)copyWithZone:(NSZone *)zone
{
    return self;
}

+ (NSUInteger)componentSizeFor:(GLLVertexAttribComponentType)componentType {
    switch (componentType) {
        case GLLVertexAttribComponentTypeByte:
        case GLLVertexAttribComponentTypeUnsignedByte:
            return 1;
        case GLLVertexAttribComponentTypeShort:
        case GLLVertexAttribComponentTypeUnsignedShort:
        case GLLVertexAttribComponentTypeHalfFloat:
            return 2;
        case GLLVertexAttribComponentTypeFloat:
        case GLLVertexAttribComponentTypeInt:
        case GLLVertexAttribComponentTypeUnsignedInt:
            return 4;
        case GLLVertexAttribComponentTypeInt2_10_10_10_Rev:
            return 1;
        default:
            return 0;
    }
}

- (NSUInteger)baseSize {
    return [[self class] componentSizeFor:self.type];
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
    if (self.type == GLLVertexAttribComponentTypeInt2_10_10_10_Rev) {
        return 4;
    }
    return self.baseSize * self.numberOfElements;
}

- (NSComparisonResult)compare:(GLLVertexAttrib *)other; {
    if (self.semantic < other.semantic) {
        return NSOrderedAscending;
    } else if (self.semantic > other.semantic) {
        return NSOrderedDescending;
    }
    
    if (self.layer < other.layer) {
        return NSOrderedAscending;
    } else if (self.layer > other.layer) {
        return NSOrderedDescending;
    }
    return NSOrderedSame;
}

@end

