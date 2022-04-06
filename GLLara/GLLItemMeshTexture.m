//
//  GLLItemMeshTexture.m
//  GLLara
//
//  Created by Torsten Kammer on 03.02.13.
//  Copyright (c) 2013 Torsten Kammer. All rights reserved.
//

#import "GLLItemMeshTexture.h"

#import "GLLItemMesh.h"

#import "GLLara-Swift.h"

@implementation GLLItemMeshTexture

@dynamic textureURL;
@dynamic textureBookmarkData;
@dynamic identifier;
@dynamic texCoordSet;
@dynamic mesh;

- (void)awakeFromFetch
{
    [super awakeFromFetch];
    
    // Get URL from bookmark
    NSData *bookmarkData = self.textureBookmarkData;
    if (bookmarkData)
    {
        NSURL *textureURL = [NSURL URLByResolvingBookmarkData:bookmarkData options:0 relativeToURL:nil bookmarkDataIsStale:NULL error:NULL];
        [self setPrimitiveValue:textureURL forKey:@"textureURL"];
    }
}

- (void)willSave
{
    // Put URL into bookmark
    NSURL *textureURL = [self primitiveValueForKey:@"textureURL"];
    if (textureURL)
    {
        NSData *bookmark = [textureURL bookmarkDataWithOptions:0 includingResourceValuesForKeys:nil relativeToURL:nil error:NULL];
        [self setPrimitiveValue:bookmark forKey:@"textureBookmarkData"];
    }
    else
        [self setPrimitiveValue:nil forKey:@"textureBookmarkData"];
}

- (void)setTexCoordSet:(int16_t)texCoordSet {
    [self willChangeValueForKey:@"texCoordSet"];
    [self setPrimitiveValue:@(texCoordSet) forKey:@"texCoordSet"];
    [self.mesh updateShader];
    [self didChangeValueForKey:@"texCoordSet"];
}

- (GLLTextureDescription *)textureDescription
{
    return [self.mesh.mesh.shader descriptionForTexture:self.identifier];
}

@end
