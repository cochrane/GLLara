//
//  GLLModelMeshV3.h
//  GLLara
//
//  Created by Torsten Kammer on 02.02.13.
//  Copyright (c) 2013 Torsten Kammer. All rights reserved.
//

#import "GLLModelMesh.h"

/*!
 * @abstract GLLModelMesh for mesh files with new header and major version set
 * to 2.
 * @discussion Important changes: No tangents included. I have no
 * damn clue how I'm supposed to know that, though. Maybe from the
 * render group? If yes, that would suck.
 */
@interface GLLModelMeshV3 : GLLModelMesh

- (NSData *)normalizeBoneWeightsInVertices:(NSData *)vertexData __attribute__((nonnull(1)));
- (NSUInteger)rawStride;

@end
