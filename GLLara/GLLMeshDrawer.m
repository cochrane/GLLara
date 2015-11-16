//
//  GLLMeshDrawer.m
//  GLLara
//
//  Created by Torsten Kammer on 01.09.12.
//  Copyright (c) 2012 Torsten Kammer. All rights reserved.
//

#import "GLLMeshDrawer.h"

#import <OpenGL/gl3.h>

#import "NSArray+Map.h"
#import "GLLModelMesh.h"
#import "GLLModelProgram.h"
#import "GLLVertexFormat.h"
#import "GLLVertexArray.h"
#import "GLLUniformBlockBindings.h"
#import "GLLResourceManager.h"
#import "GLLTexture.h"
#import "LionSubscripting.h"

@interface GLLMeshDrawer ()
{
    GLLVertexArray *vertexArray;
	GLsizei elementsCount;
    GLenum elementType;
    GLint baseVertex;
    GLvoid *indicesStart;
}

@end

@implementation GLLMeshDrawer

- (id)initWithMesh:(GLLModelMesh *)mesh vertexArray:(GLLVertexArray *)array resourceManager:(GLLResourceManager *)resourceManager error:(NSError *__autoreleasing*)error;
{
	if (!(self = [super init])) return nil;
	
	_modelMesh = mesh;
    elementsCount = (GLsizei) mesh.countOfElements;
    vertexArray = array;
    indicesStart = (GLvoid *) array.elementDataLength;
    baseVertex = (GLint) array.countOfVertices;
    
    switch (array.format.numElementBytes) {
        case 4:
            elementType = GL_UNSIGNED_INT;
            break;
        case 2:
            elementType = GL_UNSIGNED_SHORT;
            break;
        case 1:
            elementType = GL_UNSIGNED_BYTE;
            break;
        default:
            [NSException raise:NSInvalidArgumentException format:@"Can't deal with vertex format with %li bytes per index", array.format.numElementBytes];
    }
    
    [array addVertices:mesh.vertexData elements:mesh.elementData];
	
	return self;
}

- (void)drawWithState:(GLLDrawState *)state;
{	
	// Load and draw the vertices
    [vertexArray bindWithState:state];
	glDrawElementsBaseVertex(GL_TRIANGLES, elementsCount, elementType, indicesStart, baseVertex);
}

- (void)unload
{
	vertexArray = nil;
	elementsCount = 0;
}

- (void)dealloc
{
	NSAssert(vertexArray == 0 && elementsCount == 0, @"Did not call unload before calling dealloc!");
}

- (NSComparisonResult)compareTo:(GLLMeshDrawer *)other;
{
    if (vertexArray != other->vertexArray) {
        return vertexArray < other->vertexArray ? NSOrderedAscending : NSOrderedDescending;
    }
    
    return NSOrderedSame;
}

@end
