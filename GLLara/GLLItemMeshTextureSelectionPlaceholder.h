//
//  GLLItemMeshTextureSelectionPlaceholder.h
//  GLLara
//
//  Created by Torsten Kammer on 29.11.15.
//  Copyright (c) 2015 Torsten Kammer. All rights reserved.
//

#import "GLLMultipleSelectionPlaceholder.h"

/**
 * A selection placeholder for parameters on item mesh textures on an item. The source objects are assumed to be item meshes. It gets the named texture from it and then the given key path from that.
 */
@interface GLLItemMeshTextureSelectionPlaceholder : GLLMultipleSelectionPlaceholder

- (instancetype)initWithTextureName:(NSString *)textureName keyPath:(NSString *)keyPath selection:(GLLSelection *)selection;

@end
