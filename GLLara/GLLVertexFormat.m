//
//  GLLVertexFormat.m
//  GLLara
//
//  Created by Torsten Kammer on 16.11.15.
//  Copyright (c) 2015 Torsten Kammer. All rights reserved.
//

#import "GLLVertexFormat.h"

@implementation GLLVertexFormat

- (instancetype)initWithAttributes:(NSArray<GLLVertexAttrib *>*)attributes countOfVertices:(NSInteger)countOfVertices hasIndices:(BOOL)hasIndices;
{
    if (!(self = [super init])) {
        return nil;
    }
    
    _attributes = [attributes copy];
    
    _hasIndices = hasIndices;
    _indexType = MTLIndexTypeUInt32;
    if (hasIndices && countOfVertices < UINT16_MAX) {
        _indexType = MTLIndexTypeUInt16;
    }
    
    return self;
}

- (NSUInteger)hash
{
    return _indexType ^ [_attributes hash];
}

- (BOOL)isEqual:(id)object
{
    if (![object isKindOfClass:self.class])
        return NO;
    
    GLLVertexFormat *format = (GLLVertexFormat *) object;
    return format.indexType == self.indexType && format.hasIndices == self.hasIndices && [format.attributes isEqual:self.attributes];
}

- (NSInteger)stride
{
    NSInteger stride = 0;
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
