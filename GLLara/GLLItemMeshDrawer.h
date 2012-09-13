//
//  GLLItemMeshDrawer.h
//  GLLara
//
//  Created by Torsten Kammer on 06.09.12.
//  Copyright (c) 2012 Torsten Kammer. All rights reserved.
//

#import <Foundation/Foundation.h>

#import "simd_types.h"

@class GLLItemDrawer;
@class GLLMeshDrawer;
@class GLLItemMesh;

/*!
 * @abstract Draws a mesh that is part of an item.
 * @discussion This uses a mesh drawer to draw the mesh, but taking into account all the various settings the item has for this mesh - specifically, whether it is visible or not, and the render parameters that can be overriden here.
 */
@interface GLLItemMeshDrawer : NSObject

- (id)initWithItemDrawer:(GLLItemDrawer *)itemDrawer meshDrawer:(GLLMeshDrawer *)drawer itemMesh:(GLLItemMesh *)itemMesh;

@property (nonatomic, weak, readonly) GLLItemDrawer *itemDrawer;
@property (nonatomic, retain, readonly) GLLMeshDrawer *meshDrawer;
@property (nonatomic, retain, readonly) GLLItemMesh *itemMesh;

- (void)draw;

- (void)unload;

@end
