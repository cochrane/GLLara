//
//  GLLMeshDrawData.m
//  GLLara
//
//  Created by Torsten Kammer on 01.09.12.
//  Copyright (c) 2012 Torsten Kammer. All rights reserved.
//

#import "GLLMeshDrawData.h"

#import <OpenGL/gl3.h>

#import "NSArray+Map.h"
#import "GLLModelMesh.h"
#import "GLLModelProgram.h"
#import "GLLVertexFormat.h"
#import "GLLVertexArray.h"
#import "GLLUniformBlockBindings.h"
#import "GLLResourceManager.h"
#import "GLLTexture.h"

@interface GLLMeshDrawData ()
{
    GLLVertexArray *vertexArray;
}

@end

@implementation GLLMeshDrawData

@dynamic vertexArray;

- (id)initWithMesh:(GLLModelMesh *)mesh vertexArray:(GLLVertexArray *)array resourceManager:(GLLResourceManager *)resourceManager error:(NSError *__autoreleasing*)error;
{
    if (!(self = [super init])) return nil;
    
    _modelMesh = mesh;
    _elementsOrVerticesCount = (GLsizei) mesh.countOfElements;
    if (array.format.numElementBytes == 0) {
        // Rendering without elements
        _elementsOrVerticesCount = (GLsizei) mesh.countOfVertices;
    }
    vertexArray = array;
    _indicesStart = (GLsizeiptr) array.elementDataLength;
    _baseVertex = (GLint) array.countOfVertices;
    
    switch (array.format.numElementBytes) {
        case 4:
            _elementType = GL_UNSIGNED_INT;
            break;
        case 2:
            _elementType = GL_UNSIGNED_SHORT;
            break;
        case 1:
            _elementType = GL_UNSIGNED_BYTE;
            break;
        case 0:
            // Rendering without elements
            _elementType = 0;
            break;
        default:
            [NSException raise:NSInvalidArgumentException format:@"Can't deal with vertex format with %li bytes per index", array.format.numElementBytes];
    }
    
    [array addVertices:mesh.vertexDataAccessors count:mesh.countOfVertices elements:mesh.elementData elementsType:mesh.elementComponentType];
    
    return self;
}

- (void)unload
{
    vertexArray = nil;
    _elementsOrVerticesCount = 0;
}

- (void)dealloc
{
    NSAssert(vertexArray == 0 && _elementsOrVerticesCount == 0, @"Did not call unload before calling dealloc!");
}

- (GLuint)vertexArray
{
    return vertexArray.vertexArrayIndex;
}

- (NSComparisonResult)compareTo:(GLLMeshDrawData *)other;
{
    if (vertexArray != other->vertexArray) {
        return vertexArray < other->vertexArray ? NSOrderedAscending : NSOrderedDescending;
    }
    
    return NSOrderedSame;
}

@end
