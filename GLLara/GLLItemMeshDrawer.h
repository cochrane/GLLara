//
//  GLLItemMeshDrawer.h
//  GLLara
//
//  Created by Torsten Kammer on 06.09.12.
//  Copyright (c) 2012 Torsten Kammer. All rights reserved.
//

#import <Foundation/Foundation.h>

#import "GLLDrawState.h"
#import "simd_types.h"

@class GLLItemDrawer;
@class GLLMeshDrawer;
@class GLLModelProgram;
@class GLLItemMesh;

/*!
 * @abstract Draws a mesh that is part of an item.
 * @discussion This uses a mesh drawer to draw the mesh, but taking into account all the various settings the item has for this mesh - specifically, whether it is visible or not, the render parameters that can be overriden here, and the textures which can also be changed.
 */
@interface GLLItemMeshDrawer : NSObject

- (id)initWithItemDrawer:(GLLItemDrawer *)itemDrawer meshDrawer:(GLLMeshDrawer *)meshDrawer itemMesh:(GLLItemMesh *)itemMesh error:(NSError *__autoreleasing*)error;

@property (nonatomic, weak, readonly) GLLItemDrawer *itemDrawer;
@property (nonatomic, retain, readonly) GLLMeshDrawer *meshDrawer;
@property (nonatomic, retain, readonly) GLLItemMesh *itemMesh;
@property (nonatomic, retain, readonly) GLLModelProgram *program;

- (void)drawWithState:(GLLDrawState *)state;

- (void)unload;

@end
