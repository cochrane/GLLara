//
//  GLLVertexAttribAccesorSet.m
//  GLLara
//
//  Created by Torsten Kammer on 07.04.21.
//  Copyright © 2021 Torsten Kammer. All rights reserved.
//

#import "GLLVertexAttribAccessorSet.h"

#import "GLLVertexAttribAccessor.h"
#import "GLLVertexFormat.h"

#import "NSArray+Map.h"

@implementation GLLVertexAttribAccessorSet

- (instancetype)initWithAccessors:(NSArray<GLLVertexAttribAccessor *> *)accessors {
    if (!(self = [super init]))
        return nil;
    
    _accessors = [accessors copy];
    
    return self;
}

- (GLLVertexAttribAccessorSet *)setByCombiningWith:(GLLVertexAttribAccessorSet *)other;
{
    return [[[self class] alloc] initWithAccessors:[self.accessors arrayByAddingObjectsFromArray:other.accessors]];
}

- (GLLVertexAttribAccessor *__nullable)accessorForSemantic:(enum GLLVertexAttribSemantic)semantic layer:(NSUInteger)layer {
    return [self.accessors firstObjectMatching:^BOOL(GLLVertexAttribAccessor *accessor) {
        return accessor.attribute.semantic == semantic && accessor.attribute.layer == layer;
    }];
}

- (GLLVertexAttribAccessor *__nullable)accessorForSemantic:(enum GLLVertexAttribSemantic)semantic {
    return [self accessorForSemantic:semantic layer:0];
}

- (GLLVertexFormat *)vertexFormatWithVertexCount:(NSUInteger)count hasIndices:(BOOL)hasIndices {
    return [[GLLVertexFormat alloc] initWithAttributes:[self.accessors map:^GLLVertexAttrib* (GLLVertexAttribAccessor *accessor) {
        return accessor.attribute;
    }] countOfVertices:count hasIndices:hasIndices];
}

@end
