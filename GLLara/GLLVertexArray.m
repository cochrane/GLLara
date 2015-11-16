//
//  GLLVertexArray.m
//  GLLara
//
//  Created by Torsten Kammer on 16.11.15.
//  Copyright (c) 2015 Torsten Kammer. All rights reserved.
//

#import "GLLVertexArray.h"

#import "GLLVertexFormat.h"

#import <OpenGL/gl3.h>

@interface GLLVertexArray () {
    NSMutableData *vertexData;
    NSMutableData *elementData;
    GLuint vertexArrayIndex;
}

@end

@implementation GLLVertexArray

@dynamic countOfVertices;
@dynamic elementDataLength;

- (id)initWithFormat:(GLLVertexFormat *)format;
{
    if (!(self = [super init]))
        return nil;
    
    _format = format;
    vertexData = [[NSMutableData alloc] init];
    elementData = [[NSMutableData alloc] init];
    
    return self;
}

- (NSUInteger)countOfVertices
{
    return vertexData.length / self.format.stride;
}

- (NSUInteger)elementDataLength
{
    return elementData.length;
}

- (void)addVertices:(NSData *)vertices elements:(NSData *)elementsUInt32;
{
    [vertexData appendData:vertices];
    
    if (self.format.numElementBytes == 4) {
        [elementData appendData:elementsUInt32];
    } else if (self.format.numElementBytes == 2) {
        NSUInteger numElements = elementsUInt32.length / 4;
        const uint32_t *originalElements = elementsUInt32.bytes;
        
        uint16_t *elements = malloc(numElements * 2);
        for (NSUInteger i = 0; i < numElements; i++) {
            elements[i] = (uint16_t) originalElements[i];
        }
        [elementData appendBytes:elements length:numElements * 2];
        free(elements);
    } else if (self.format.numElementBytes == 1) {
        NSUInteger numElements = elementsUInt32.length / 4;
        const uint32_t *originalElements = elementsUInt32.bytes;
        
        uint8_t *elements = malloc(numElements);
        for (NSUInteger i = 0; i < numElements; i++) {
            elements[i] = (uint8_t) originalElements[i];
        }
        [elementData appendBytes:elements length:numElements];
        free(elements);
    } else {
        [NSException raise:@"Illegal state" format:@"Can't handle vertex buffer with %li bytes per element", self.format.numElementBytes];
    }
}

- (void)upload;
{
    // Create the element and vertex buffers, and spend a lot of time setting up the vertex attribute arrays and pointers.
    glGenVertexArrays(1, &vertexArrayIndex);
    glBindVertexArray(vertexArrayIndex);
    
    GLuint buffers[2];
    glGenBuffers(2, buffers);
    
    glBindBuffer(GL_ARRAY_BUFFER, buffers[0]);
    glBufferData(GL_ARRAY_BUFFER, vertexData.length, vertexData.bytes, GL_STATIC_DRAW);
    
    glEnableVertexAttribArray(GLLVertexAttribPosition);
    glVertexAttribPointer(GLLVertexAttribPosition, 3, GL_FLOAT, GL_FALSE, (GLsizei) self.format.stride, (GLvoid *) self.format.offsetForPosition);
    
    glEnableVertexAttribArray(GLLVertexAttribNormal);
    glVertexAttribPointer(GLLVertexAttribNormal, 3, GL_FLOAT, GL_FALSE, (GLsizei) self.format.stride, (GLvoid *) self.format.offsetForNormal);
    
    glEnableVertexAttribArray(GLLVertexAttribColor);
    glVertexAttribPointer(GLLVertexAttribColor, 4, GL_UNSIGNED_BYTE, GL_TRUE, (GLsizei) self.format.stride, (GLvoid *) self.format.offsetForColor);
    
    if (self.format.hasBoneWeights)
    {
        glEnableVertexAttribArray(GLLVertexAttribBoneIndices);
        glVertexAttribIPointer(GLLVertexAttribBoneIndices, 4, GL_UNSIGNED_SHORT, (GLsizei) self.format.stride, (GLvoid *) self.format.offsetForBoneIndices);
        
        glEnableVertexAttribArray(GLLVertexAttribBoneWeights);
        glVertexAttribPointer(GLLVertexAttribBoneWeights, 4, GL_FLOAT, GL_FALSE, (GLsizei) self.format.stride, (GLvoid *) self.format.offsetForBoneWeights);
    }
    
    for (GLuint i = 0; i < self.format.countOfUVLayers; i++)
    {
        glEnableVertexAttribArray(GLLVertexAttribTexCoord0 + 2*i);
        glVertexAttribPointer(GLLVertexAttribTexCoord0 + 2*i, 2, GL_FLOAT, GL_FALSE, (GLsizei) self.format.stride, (GLvoid *) [self.format offsetForTexCoordLayer:i]);
        
        if (self.format.hasTangents)
        {
            glEnableVertexAttribArray(GLLVertexAttribTangent0 + 2*i);
            glVertexAttribPointer(GLLVertexAttribTangent0 + 2*i, 4, GL_FLOAT, GL_FALSE, (GLsizei) self.format.stride, (GLvoid *) [self.format offsetForTangentLayer:i]);
        }
    }
    
    
    glBindBuffer(GL_ELEMENT_ARRAY_BUFFER, buffers[1]);
    glBufferData(GL_ELEMENT_ARRAY_BUFFER, elementData.length, elementData.bytes, GL_STATIC_DRAW);
    
    glBindVertexArray(0);
    glDeleteBuffers(2, buffers);

    vertexData = nil;
    elementData = nil;
}

- (void)bindWithState:(GLLDrawState *)state
{
    if (state->activeVertexArray != vertexArrayIndex) {
        glBindVertexArray(vertexArrayIndex);
        state->activeVertexArray = vertexArrayIndex;
    }
}

- (void)unload
{
    glDeleteVertexArrays(1, vertexArrayIndex);
    vertexArrayIndex = 0;
}

@end
