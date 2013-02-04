//
//  GLLItemMeshTexture.h
//  GLLara
//
//  Created by Torsten Kammer on 03.02.13.
//  Copyright (c) 2013 Torsten Kammer. All rights reserved.
//

#import <Foundation/Foundation.h>
#import <CoreData/CoreData.h>

@class GLLItemMesh;
@class GLLTextureDescription;

/*!
 * @abstract Stores which textures are associated with which uniform values.
 */
@interface GLLItemMeshTexture : NSManagedObject

// URL of the texture
@property (nonatomic, retain) NSURL *textureURL;
@property (nonatomic, retain) NSData * textureBookmarkData;

// A string identifying the purpose/shader uniform variable this texture is
// bound to.
@property (nonatomic, retain) NSString * identifier;

// The mesh this texture belongs to.
@property (nonatomic, retain) GLLItemMesh *mesh;

// Description
@property (nonatomic, readonly) GLLTextureDescription *textureDescription;

@end
