//
//  GLLTestObjectWriter.h
//  GLLara
//
//  Created by Torsten Kammer on 07.03.13.
//  Copyright (c) 2013 Torsten Kammer. All rights reserved.
//

#import <Foundation/Foundation.h>

/*!
 * @abstract Creates a simple test object with different configurations.
 * @discussion The test object can be configured with an arbitrary number of bones and meshes. The final object is a series of cubes with shared faces, with each cube having one bone and/or mesh. The number of cubes is the larger of bones and meshes. If there are more cubes than bones, the final cubes all belong to the final bone. Likewise, if there are less meshes than cubes, the final cubes belong to the final mesh.
 * Bones are always named bone0…n, meshes mesh0…n. Each bone is the child of its predecessor (except for the first of course).
 */

@interface GLLTestObjectWriter : NSObject

@property (nonatomic) NSUInteger numBones;
@property (nonatomic) NSUInteger numMeshes;

- (void)setNumUVLayers:(NSUInteger)layers forMesh:(NSUInteger)mesh;
- (void)addTextureFilename:(NSString *)name uvLayer:(NSUInteger)layer toMesh:(NSUInteger)mesh;
- (void)setRenderGroup:(NSUInteger)group renderParameterValues:(NSArray *)values forMesh:(NSUInteger)mesh;

@property (nonatomic, readonly) NSString *testFileString;

@end
