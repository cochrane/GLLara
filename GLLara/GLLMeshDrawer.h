//
//  GLLMeshDrawer.h
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
@interface GLLMeshDrawer : NSObject

- (id)initWithMesh:(GLLModelMesh *)mesh vertexArray:(GLLVertexArray *)vertexArray resourceManager:(GLLResourceManager *)resourceManager error:(NSError *__autoreleasing*)error;

@property (nonatomic, retain, readonly) GLLModelMesh *modelMesh;

- (void)drawWithState:(GLLDrawState *)state;

- (void)unload;

@end
