//
//  GLLVertexAttribAccessor.m
//  GLLara
//
//  Created by Torsten Kammer on 06.04.21.
//  Copyright © 2021 Torsten Kammer. All rights reserved.
//

#import "GLLVertexAttribAccessor.h"

@implementation GLLVertexAttribAccessor

- (instancetype)initWithSemantic:(enum GLLVertexAttribSemantic)semantic layer:(NSUInteger) layer size:(enum GLLVertexAttribSize)size componentType:(enum GLLVertexAttribComponentType)type dataBuffer:(NSData *__nullable)dataBuffer offset:(NSUInteger)dataOffset stride:(NSUInteger)stride;
{
    return [self initWithAttribute:[[GLLVertexAttrib alloc] initWithSemantic:semantic layer:layer size:size componentType:type] dataBuffer:dataBuffer offset:dataOffset stride:stride];
}

- (instancetype)initWithAttribute:(GLLVertexAttrib *)attribute dataBuffer:(NSData *__nullable)dataBuffer offset:(NSUInteger)dataOffset stride:(NSUInteger)stride;
{
    if (!(self = [super init]))
        return nil;
    
    _attribute = attribute;
    _dataBuffer = dataBuffer;
    _dataOffset = dataOffset;
    _stride = stride;
    
    return self;
}

- (NSUInteger)offsetForElement:(NSUInteger)index {
    return _dataOffset + index * _stride;
}

- (const void *)elementAt:(NSUInteger)index {
    if (!_dataBuffer) return NULL;
    
    return _dataBuffer.bytes + [self offsetForElement:index];
}

- (NSData *)elementDataAt:(NSUInteger)index {
    NSRange range = NSMakeRange([self offsetForElement:index], self.attribute.sizeInBytes);
    NSAssert(_dataBuffer != nil && NSMaxRange(range) <= _dataBuffer.length, @"Needs to be in range");
    return [_dataBuffer subdataWithRange:range];
}

@end
