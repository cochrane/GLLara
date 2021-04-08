//
//  GLLMeshDrawData.h
//  GLLara
//
//  Created by Torsten Kammer on 01.09.12.
//  Copyright (c) 2012 Torsten Kammer. All rights reserved.
//

#import <Foundation/Foundation.h>

#import "simd_types.h"
#import "GLLDrawState.h"

@class GLLModelMesh;
@class GLLModelProgram;
@class GLLResourceManager;
@class GLLVertexArray;

/*!
 * @abstract Draws a single mesh.
 * @discussion This class contains only the mesh data and the program for rendering. In the future, the program  might be moved to the ItemMeshDrawer, leaving this with only the geometry. There is one mesh drawer per mesh per loaded model. Several ItemMeshDrawer can share one.
 */
@interface GLLMeshDrawData : NSObject

- (id)initWithMesh:(GLLModelMesh *)mesh vertexArray:(GLLVertexArray *)vertexArray resourceManager:(GLLResourceManager *)resourceManager error:(NSError *__autoreleasing*)error;

@property (nonatomic, retain, readonly) GLLModelMesh *modelMesh;
@property (nonatomic, assign, readonly) GLenum elementType;
@property (nonatomic, assign, readonly) GLint baseVertex;
@property (nonatomic, assign, readonly) GLsizeiptr indicesStart;
@property (nonatomic, assign, readonly) GLsizei elementsOrVerticesCount;
@property (nonatomic, assign, readonly) GLuint vertexArray;

- (void)unload;

/*!
 * Compares this with another mesh drawer to figure out an order in which they cause the fewest state changes. The only guarantee is that the order is stable, and that if no state has to be changed, the result will be equal.
 */
- (NSComparisonResult)compareTo:(GLLMeshDrawData *)other;

@end
