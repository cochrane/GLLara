//
//  GLLVertexAttribAccessor.m
//  GLLara
//
//  Created by Torsten Kammer on 06.04.21.
//  Copyright © 2021 Torsten Kammer. All rights reserved.
//

#import "GLLVertexAttribAccessor.h"

@implementation GLLVertexAttribAccessor

- (instancetype)initWithSemantic:(enum GLLVertexAttribSemantic)semantic layer:(NSInteger) layer format:(MTLVertexFormat)format dataBuffer:(NSData *__nullable)dataBuffer offset:(NSInteger)dataOffset stride:(NSInteger)stride;
{
    return [self initWithAttribute:[[GLLVertexAttrib alloc] initWithSemantic:semantic layer:layer format:format] dataBuffer:dataBuffer offset:dataOffset stride:stride];
}

- (instancetype)initWithAttribute:(GLLVertexAttrib *)attribute dataBuffer:(NSData *__nullable)dataBuffer offset:(NSInteger)dataOffset stride:(NSInteger)stride;
{
    if (!(self = [super init]))
        return nil;
    
    _attribute = attribute;
    _dataBuffer = dataBuffer;
    _dataOffset = dataOffset;
    
    if (stride == 0) {
        // As always in GL world, a stride of 0 means "calculate it yourself", not actually 0, which would make no sense.
        _stride = attribute.sizeInBytes;
    } else {
        _stride = stride;
    }
    
    return self;
}

- (NSInteger)offsetForElement:(NSInteger)index {
    return _dataOffset + index * _stride;
}

- (const void *)elementAt:(NSInteger)index {
    if (!_dataBuffer) return NULL;
    
    return _dataBuffer.bytes + [self offsetForElement:index];
}

- (NSData *)elementDataAt:(NSInteger)index {
    NSRange range = NSMakeRange([self offsetForElement:index], self.attribute.sizeInBytes);
    NSAssert(_dataBuffer != nil && NSMaxRange(range) <= _dataBuffer.length, @"Needs to be in range");
    return [_dataBuffer subdataWithRange:range];
}

@end
