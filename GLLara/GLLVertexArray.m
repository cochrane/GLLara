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

@property (nonatomic, readonly, assign) NSUInteger actualStride;
@property (nonatomic, readonly, assign) NSUInteger offsetForPosition;
@property (nonatomic, readonly, assign) NSUInteger offsetForNormal;
@property (nonatomic, readonly, assign) NSUInteger offsetForColor;
@property (nonatomic, readonly, assign) NSUInteger offsetForBoneIndices;
@property (nonatomic, readonly, assign) NSUInteger offsetForBoneWeights;

- (NSUInteger)offsetForTexCoordLayer:(NSUInteger)layer;
- (NSUInteger)offsetForTangentLayer:(NSUInteger)layer;

@end

@implementation GLLVertexArray

@dynamic countOfVertices;
@dynamic elementDataLength;
@dynamic actualStride;
@dynamic offsetForPosition, offsetForNormal, offsetForColor, offsetForBoneIndices, offsetForBoneWeights;

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
    return vertexData.length / self.actualStride;
}

- (NSUInteger)elementDataLength
{
    return elementData.length;
}

- (NSUInteger)actualStride
{
    NSInteger offset = -8; // For normal
    if (self.format.hasBoneWeights)
        offset -= 8; // For bone weights;
    if (self.format.hasTangents)
        offset -= 12 * self.format.countOfUVLayers; // For tangents
    return self.format.stride + offset;
}

- (NSUInteger)offsetForPosition
{
    return self.format.offsetForPosition;
}

- (NSUInteger)offsetForNormal
{
    return self.format.offsetForNormal;
}

- (NSUInteger)offsetForColor
{
    NSInteger offset = -8; // For normal
    return self.format.offsetForColor + offset;
}

- (NSUInteger)offsetForBoneIndices
{
    NSInteger offset = -8; // For normal
    if (self.format.hasTangents)
        offset -= 12 * self.format.countOfUVLayers; // For tangents
    return self.format.offsetForBoneIndices + offset;
}

- (NSUInteger)offsetForBoneWeights
{
    NSInteger offset = -8; // For normal
    if (self.format.hasTangents)
        offset -= 12 * self.format.countOfUVLayers; // For tangents
    return self.format.offsetForBoneWeights + offset;
}

- (NSUInteger)offsetForTexCoordLayer:(NSUInteger)layer
{
    NSInteger offset = -8; // For normal
    if (self.format.hasTangents)
        offset -= 12 * layer; // For tangents
    return [self.format offsetForTexCoordLayer:layer] + offset;
}

- (NSUInteger)offsetForTangentLayer:(NSUInteger)layer
{
    NSInteger offset = -8; // For normal
    if (self.format.hasTangents)
        offset -= 12 * layer; // For tangents
    return [self.format offsetForTangentLayer:layer] + offset;
}

- (void)addVertices:(NSData *)vertices elements:(NSData *)elementsUInt32;
{
    // Process vertex data
    NSUInteger originalStride = self.format.stride;
    NSUInteger actualStride = self.actualStride;
    NSUInteger numElements = vertices.length / originalStride;
    void *newBytes = malloc(numElements * actualStride);
    NSUInteger countOfUVLayers = self.format.countOfUVLayers;
    BOOL hasTangents = self.format.hasTangents;
    
    for (NSUInteger i = 0; i < numElements; i++) {
        const void *originalVertex = vertices.bytes + originalStride * i;
        void *vertex = newBytes + actualStride * i;
        
        // Position
        memcpy(vertex, originalVertex, 12);
        vertex += 12;
        originalVertex += 12;
        
        // Normal. Compress from float[3] to int_2_10_10_10_rev format
        uint32_t *value = vertex;
        const float *normal = originalVertex;
        *value = 0;
        *value += ((int) (normal[0] * 512.0) & 0x3FF);
        *value += (((int) (normal[1] * 512.0) & 0x3FF)) << 10;
        *value += (((int) (normal[2] * 512.0) & 0x3FF)) << 20;
        vertex += 4;
        originalVertex += 12;
        
        // Color
        memcpy(vertex, originalVertex, 4);
        vertex += 4;
        originalVertex += 4;
        
        // Tex coords + tangents
        for (NSUInteger j = 0; j < countOfUVLayers; j++) {
            memcpy(vertex, originalVertex, 8);
            vertex += 8;
            originalVertex += 8;
            
            if (hasTangents) {
                uint32_t *value = vertex;
                const float *tangent = originalVertex;
                *value = 0;
                *value += ((int) (tangent[0] * 512.0) & 0x3FF);
                *value += (((int) (tangent[1] * 512.0) & 0x3FF)) << 10;
                *value += (((int) (tangent[2] * 512.0) & 0x3FF)) << 20;
                if (tangent[3] > 0.0f) {
                    *value += (1 & 0x3) << 30;
                } else {
                    *value += (-1 & 0x3) << 30;
                }
                
                vertex += 4;
                originalVertex += 16;
            }
        }
        
        // Bone weights (if applicable)
        if (self.format.hasBoneWeights) {
            memcpy(vertex, originalVertex, 8); // Bone indices
            vertex += 8;
            originalVertex += 8;
            
            const float *weights = originalVertex;
            uint16_t *intWeights = vertex;
            for (int j = 0; j < 4; j++) {
                intWeights[j] = (uint16_t) (weights[j] * UINT16_MAX);
            }
            originalVertex += 16;
            vertex += 8;
        }
    }
    
    [vertexData appendBytes:newBytes length:numElements * self.actualStride];
    free(newBytes);
    
    // Compress elements
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
    
    GLsizei actualStride = (GLsizei) self.actualStride;
    
    glEnableVertexAttribArray(GLLVertexAttribPosition);
    glVertexAttribPointer(GLLVertexAttribPosition, 3, GL_FLOAT, GL_FALSE, actualStride, (GLvoid *) self.offsetForPosition);
    
    glEnableVertexAttribArray(GLLVertexAttribNormal);
    glVertexAttribPointer(GLLVertexAttribNormal, 4, GL_INT_2_10_10_10_REV, GL_TRUE, actualStride, (GLvoid *) self.offsetForNormal);
    
    glEnableVertexAttribArray(GLLVertexAttribColor);
    glVertexAttribPointer(GLLVertexAttribColor, 4, GL_UNSIGNED_BYTE, GL_TRUE, actualStride, (GLvoid *) self.offsetForColor);
    
    if (self.format.hasBoneWeights)
    {
        glEnableVertexAttribArray(GLLVertexAttribBoneIndices);
        glVertexAttribIPointer(GLLVertexAttribBoneIndices, 4, GL_UNSIGNED_SHORT, actualStride, (GLvoid *) self.offsetForBoneIndices);
        
        glEnableVertexAttribArray(GLLVertexAttribBoneWeights);
        glVertexAttribPointer(GLLVertexAttribBoneWeights, 4, GL_UNSIGNED_SHORT, GL_TRUE, actualStride, (GLvoid *) self.offsetForBoneWeights);
    }
    
    for (GLuint i = 0; i < self.format.countOfUVLayers; i++)
    {
        glEnableVertexAttribArray(GLLVertexAttribTexCoord0 + 2*i);
        glVertexAttribPointer(GLLVertexAttribTexCoord0 + 2*i, 2, GL_FLOAT, GL_FALSE, actualStride, (GLvoid *) [self offsetForTexCoordLayer:i]);
        
        if (self.format.hasTangents)
        {
            glEnableVertexAttribArray(GLLVertexAttribTangent0 + 2*i);
            glVertexAttribPointer(GLLVertexAttribTangent0 + 2*i, 4, GL_INT_2_10_10_10_REV, GL_TRUE, actualStride, (GLvoid *) [self offsetForTangentLayer:i]);
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
