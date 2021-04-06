//
//  GLLVertexArray.m
//  GLLara
//
//  Created by Torsten Kammer on 16.11.15.
//  Copyright (c) 2015 Torsten Kammer. All rights reserved.
//

#import "GLLVertexArray.h"

#import "GLLVertexFormat.h"
#import "NSArray+Map.h"

#import <OpenGL/gl3.h>

@interface GLLVertexArray () {
    NSMutableData *vertexData;
    NSMutableData *elementData;
    GLuint vertexArrayIndex;
    NSIndexSet *attributesToMap;
}

- (GLLVertexAttribAccessor *)optimizedVersionOf:(GLLVertexAttribAccessor *)accessor;
@property (nonatomic, readonly, copy) GLLVertexFormat *optimizedFormat;

@end

static inline uint32_t packSignedFloat(float value, int bits)
{
    /*
     f(1.0) = max
     f(-1.0) = min
     1.0 * m + a = max
     -1.0 * m + a = min
     2a = max + min
     a = 0.5*(max+min)
     1.0 * m + 0.5*(max+min) = max
     m = max - 0.5*(max+min)
     
     */
    
    int32_t max = (1 << (bits-1)) - 1;
    int32_t min = -(1 << (bits-1));
    float offset = 0.5 * (max+min);
    float factor = max - offset;
    float scaled = value * factor + offset;
    int32_t signedValue = (int32_t) scaled;
    uint32_t mask = (1 << bits) - 1;
    return signedValue & mask;
}

static inline uint32_t reduceFloat(const float *value, unsigned exponentBits, unsigned mantissaBits, unsigned signBits) {
    uint32_t valueBits = ((uint32_t *) value)[0];
    
    uint32_t mantissa = valueBits & ((1 << 23) - 1);
    int32_t exponent = ((valueBits >> 23) & 0xFF) - 127;
    uint32_t sign = (valueBits >> 31) & 0x1;
    
    uint32_t bias = (1 << (exponentBits - 1)) - 1;
    int32_t newExponent = exponent + bias;
    int32_t maxBiasedExponent = (1 << exponentBits) - 1;
    if (newExponent <= 0) {
        // Set to 0. Don't muck around with denormals
        newExponent = 0;
        mantissa = 0;
    } else if (newExponent >= maxBiasedExponent) {
        // Set to inf.
        newExponent = maxBiasedExponent;
        mantissa = 0;
    }
    
    uint32_t result = 0;
    // Mantissa
    result |= mantissa >> (23 - mantissaBits);
    
    // Exponent
    result |= newExponent << mantissaBits;
    
    if (signBits > 0) {
        result |= sign << (exponentBits + mantissaBits);
    }
    return result;
}

static inline uint16_t halfFloat(const float *value) {
    return (uint16_t) reduceFloat(value, 5, 10, 1);
}

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
    
    NSMutableIndexSet *changedAttributes = [[NSMutableIndexSet alloc] init];
    NSMutableArray *optimizedAttributes = [[NSMutableArray alloc] init];
    for (NSUInteger i = 0; i < format.attributes.count; i++) {
        GLLVertexAttribAccessor *accessor = format.attributes[i];
        GLLVertexAttribAccessor *optimized = [self optimizedVersionOf:accessor];
        if (![accessor isEqual:optimized]) {
            [changedAttributes addIndex:i];
        }
        [optimizedAttributes addObject:optimized];
    }
    
    _optimizedFormat = [[GLLVertexFormat alloc] initWithAttributes:optimizedAttributes countOfVertices:0];
    attributesToMap = [changedAttributes copy];
    
    return self;
}

- (GLLVertexAttribAccessor *)optimizedVersionOf:(GLLVertexAttribAccessor *)accessor {
    // Change Normal (if float[3]) to vec4 with 2_10_10_10_rev encoding
    // (this adds a W component which gets ignored by the shader)
    if (accessor.attrib == GLLVertexAttribNormal && accessor.size == GLLVertexAttribSizeVec3 && accessor.type == GllVertexAttribComponentTypeFloat) {
        return [[GLLVertexAttribAccessor alloc] initWithAttrib:accessor.attrib layer:accessor.layer size:GLLVertexAttribSizeVec4 componentType:GllVertexAttribComponentTypeInt2_10_10_10_Rev];
    }
    // Change tex coord (if float[2]) to half[2]
    if (accessor.attrib == GLLVertexAttribTexCoord0 && accessor.size == GLLVertexAttribSizeVec2 && accessor.type == GllVertexAttribComponentTypeFloat) {
        return [[GLLVertexAttribAccessor alloc] initWithAttrib:accessor.attrib layer:accessor.layer size:GLLVertexAttribSizeVec2 componentType:GllVertexAttribComponentTypeHalfFloat];
    }
    // Change tangent (if float[4]) to vec4 with 2_10_10_10_rev encoding
    if (accessor.attrib == GLLVertexAttribTangent0 && accessor.size == GLLVertexAttribSizeVec4 && accessor.type == GllVertexAttribComponentTypeFloat) {
        return [[GLLVertexAttribAccessor alloc] initWithAttrib:accessor.attrib layer:accessor.layer size:GLLVertexAttribSizeVec4 componentType:GllVertexAttribComponentTypeInt2_10_10_10_Rev];
    }
    // Change bone weight (if float[4]) to half[4]
    if (accessor.attrib == GLLVertexAttribBoneWeights && accessor.size == GLLVertexAttribSizeVec4 && accessor.type == GllVertexAttribComponentTypeFloat) {
        return [[GLLVertexAttribAccessor alloc] initWithAttrib:accessor.attrib layer:accessor.layer size:GLLVertexAttribSizeVec4 componentType:GllVertexAttribComponentTypeUnsignedShort];
    }
    return accessor;
}

- (NSUInteger)countOfVertices
{
    return vertexData.length / self.optimizedFormat.stride;
}

- (NSUInteger)elementDataLength
{
    return elementData.length;
}

- (void)addVertices:(NSData *)vertices elements:(NSData *)elementsUInt32;
{
    // Process vertex data
    NSUInteger originalStride = self.format.stride;
    NSUInteger actualStride = self.optimizedFormat.stride;
    NSUInteger numElements = vertices.length / originalStride;
    void *newBytes = malloc(numElements * actualStride);
    
    for (NSUInteger i = 0; i < numElements; i++) {
        const void *originalVertex = vertices.bytes + originalStride * i;
        void *vertex = newBytes + actualStride * i;
        
        for (NSUInteger attributeIndex = 0; attributeIndex < self.format.attributes.count; attributeIndex++) {
            GLLVertexAttribAccessor *accessor = self.format.attributes[attributeIndex];
            if ([attributesToMap containsIndex:attributeIndex]) {
                // Need to do some processing
                if (accessor.attrib == GLLVertexAttribNormal && accessor.size == GLLVertexAttribSizeVec3 && accessor.type == GllVertexAttribComponentTypeFloat) {
                    // Normal. Compress from float[3] to int_2_10_10_10_rev format
                    uint32_t *value = vertex;
                    const float *normal = originalVertex;
                    *value = 0;
                    *value += packSignedFloat(normal[0], 10);
                    *value += packSignedFloat(normal[1], 10) << 10;
                    *value += packSignedFloat(normal[2], 10) << 20;
                } else if (accessor.attrib == GLLVertexAttribTexCoord0 && accessor.size == GLLVertexAttribSizeVec2 && accessor.type == GllVertexAttribComponentTypeFloat) {
                    // Tex coord. Compress to half float
                    uint16_t *intTexCoords = vertex;
                    const float *floatTexCoords = originalVertex;
                    intTexCoords[0] = halfFloat(floatTexCoords + 0);
                    intTexCoords[1] = halfFloat(floatTexCoords + 1);
                } else if (accessor.attrib == GLLVertexAttribTangent0 && accessor.size == GLLVertexAttribSizeVec4 && accessor.type == GllVertexAttribComponentTypeFloat) {
                    // Compress tangent from float[3] to int_2_10_10_10_rev
                    const float *tangents = originalVertex;
                    uint32_t *normalized = vertex;
                    float invLength = 1.0f / sqrtf(tangents[0]*tangents[0] + tangents[1]*tangents[1] + tangents[2]*tangents[2]);
                    *normalized = 0;
                    *normalized |= packSignedFloat(tangents[0] * invLength, 10);
                    *normalized |= packSignedFloat(tangents[1] * invLength, 10) << 10;
                    *normalized |= packSignedFloat(tangents[2] * invLength, 10) << 20;
                    *normalized |= packSignedFloat(copysign(tangents[3], 1.0f), 2) << 30;
                } else if (accessor.attrib == GLLVertexAttribBoneWeights && accessor.size == GLLVertexAttribSizeVec4 && accessor.type == GllVertexAttribComponentTypeFloat) {
                    // Compress bone weight to half float
                    const float *weights = originalVertex;
                    uint16_t *intWeights = vertex;
                    float sum = weights[0] + weights[1] + weights[2] + weights[3];
                    if (sum == 0.0f) {
                        intWeights[0] = UINT16_MAX;
                        intWeights[1] = 0;
                        intWeights[2] = 0;
                        intWeights[3] = 0;
                    } else {
                        for (int j = 0; j < 4; j++) {
                            intWeights[j] = (uint16_t) packSignedFloat(weights[j] / sum, 16);
                        }
                    }
                }
            } else {
                memcpy(vertex, originalVertex, accessor.sizeInBytes);
            }
            originalVertex += accessor.sizeInBytes;
            vertex += self.optimizedFormat.attributes[attributeIndex].sizeInBytes;
        }
    }
    
    [vertexData appendBytes:newBytes length:numElements * self.optimizedFormat.stride];
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
    
    GLsizei actualStride = (GLsizei) self.optimizedFormat.stride;
    
    NSUInteger offset = 0;
    for (GLLVertexAttribAccessor *accessor in self.optimizedFormat.attributes) {
        GLuint attribIndex = accessor.attrib;
        if (accessor.attrib == GLLVertexAttribTangent0 || accessor.attrib == GLLVertexAttribTexCoord0) {
            attribIndex += 2 * accessor.layer;
        }
        
        glEnableVertexAttribArray(attribIndex);
        
        if (accessor.attrib == GLLVertexAttribBoneIndices) {
            glVertexAttribIPointer(attribIndex, (GLint) accessor.numberOfElements, accessor.type, actualStride, (GLvoid *) offset);
        } else {
            GLenum normalized = GL_FALSE;
            if (accessor.type == GL_UNSIGNED_BYTE && accessor.attrib == GLLVertexAttribColor) {
                normalized = GL_TRUE;
            } else if (accessor.type == GL_INT_2_10_10_10_REV) {
                normalized = GL_TRUE;
            } else if (accessor.type == GL_UNSIGNED_SHORT && accessor.attrib == GLLVertexAttribBoneWeights) {
                normalized = GL_TRUE;
            }
            glVertexAttribPointer(attribIndex, (GLint) accessor.numberOfElements, accessor.type, normalized, actualStride, (GLvoid *) offset);
        }
        offset += accessor.sizeInBytes;
    }
        
    glBindBuffer(GL_ELEMENT_ARRAY_BUFFER, buffers[1]);
    glBufferData(GL_ELEMENT_ARRAY_BUFFER, elementData.length, elementData.bytes, GL_STATIC_DRAW);
    
    glBindVertexArray(0);
    glDeleteBuffers(2, buffers);
    
    vertexData = nil;
    elementData = nil;
}

- (GLuint)vertexArrayIndex
{
    return vertexArrayIndex;
}

- (void)unload
{
    glDeleteVertexArrays(1, &vertexArrayIndex);
    vertexArrayIndex = 0;
}

@end
