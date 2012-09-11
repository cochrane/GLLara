//
//  GLLTransformedMeshDrawer.h
//  GLLara
//
//  Created by Torsten Kammer on 06.09.12.
//  Copyright (c) 2012 Torsten Kammer. All rights reserved.
//

#import <Foundation/Foundation.h>

#import "simd_types.h"

@class GLLMeshDrawer;
@class GLLMeshSettings;

/*!
 * @abstract Draws a mesh that is part of an item.
 * @discussion This uses a mesh drawer to draw the mesh, but taking into account all the various settings the item has for this mesh - specifically, whether it is visible or not, and the render parameters that can be overriden here.
 */
@interface GLLTransformedMeshDrawer : NSObject

- (id)initWithDrawer:(GLLMeshDrawer *)drawer settings:(GLLMeshSettings *)settings;

@property (nonatomic, retain, readonly) GLLMeshDrawer *drawer;
@property (nonatomic, retain, readonly) GLLMeshSettings *settings;

- (void)draw;

- (void)unload;

@end
