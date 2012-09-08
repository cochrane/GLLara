//
//  GLLMeshDrawer.h
//  GLLara
//
//  Created by Torsten Kammer on 01.09.12.
//  Copyright (c) 2012 Torsten Kammer. All rights reserved.
//

#import <Foundation/Foundation.h>

#import "simd_types.h"

@class GLLMesh;
@class GLLProgram;
@class GLLResourceManager;

@interface GLLMeshDrawer : NSObject

- (id)initWithMesh:(GLLMesh *)mesh resourceManager:(GLLResourceManager *)resourceManager error:(NSError *__autoreleasing*)error;

@property (nonatomic, retain, readonly) GLLMesh *mesh;
@property (nonatomic, retain, readonly) GLLProgram *program;
@property (nonatomic, copy, readonly) NSArray *textures;

- (void)drawWithTransforms:(const mat_float16 *)transforms;

- (void)unload;

@end
