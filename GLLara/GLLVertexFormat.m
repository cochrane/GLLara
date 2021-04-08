//
//  GLLVertexFormat.m
//  GLLara
//
//  Created by Torsten Kammer on 16.11.15.
//  Copyright (c) 2015 Torsten Kammer. All rights reserved.
//

#import "GLLVertexFormat.h"

@implementation GLLVertexFormat

- (instancetype)initWithAttributes:(NSArray<GLLVertexAttrib *>*)attributes countOfVertices:(NSUInteger)countOfVertices hasIndices:(BOOL)hasIndices;
{
    if (!(self = [super init])) {
        return nil;
    }
    
    _attributes = [attributes copy];
    
    if (hasIndices) {
        if (countOfVertices < UINT8_MAX)
            _numElementBytes = 1;
        else if (countOfVertices < UINT16_MAX)
            _numElementBytes = 2;
        else if (countOfVertices < UINT32_MAX)
            _numElementBytes = 4;
        else
            [NSException raise:NSInvalidArgumentException format:@"%li vertices outside allowed range", countOfVertices];
    } else {
        _numElementBytes = 0;
    }
    
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

- (NSUInteger)stride
{
    NSUInteger stride = 0;
    for (GLLVertexAttrib *attribute in self.attributes) {
        stride += attribute.sizeInBytes;
    }
    return stride;
}

- (BOOL)hasIndices {
    return _numElementBytes > 0;
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
