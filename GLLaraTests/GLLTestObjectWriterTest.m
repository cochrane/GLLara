//
//  GLLTestObjectWriterTest.m
//  GLLara
//
//  Created by Torsten Kammer on 08.03.13.
//  Copyright (c) 2013 Torsten Kammer. All rights reserved.
//

#import "GLLTestObjectWriterTest.h"

#import "GLLTestObjectWriter.h"
#import "GLLModel.h"
#import "GLLModelBone.h"
#import "GLLModelMesh.h"

@implementation GLLTestObjectWriterTest

- (void)testSimple
{
    GLLTestObjectWriter *writer = [[GLLTestObjectWriter alloc] init];
    writer.numBones = 1;
    writer.numMeshes = 1;
    [writer setRenderGroup:1 renderParameterValues:@[ @(12) ] forMesh:0];
    NSString *contents = writer.testFileString;
    XCTAssertNotNil(contents, @"Writer didn't write anything.");
    
    NSError *error = nil;
    GLLModel *model = [[GLLModel alloc] initASCIIFromString:contents baseURL:[NSURL fileURLWithPath:@"/var/tmp/generic_item.mesh.ascii"] parent:nil error:&error];
    XCTAssertNotNil(model, @"Couldn't read test object");
    XCTAssertNil(error, @"Produced error: %@", error);
    
    XCTAssertEqual(model.bones.count, 1UL, @"Should have one bone!");
    XCTAssertEqual(model.meshes.count, 1UL, @"Should have one mesh!");
    
    // Test bone
    GLLModelBone *bone = [model.bones objectAtIndex:0];
    XCTAssertEqualObjects(bone.name, @"bone0", @"incorrect name");
    XCTAssertNil(bone.parent, @"should not have a parent, has %@", bone.parent);
    XCTAssertEqualWithAccuracy(bone.positionX, 0.0f, 0.001f, @"wrong position");
    XCTAssertEqualWithAccuracy(bone.positionY, 0.0f, 0.001f, @"wrong position");
    XCTAssertEqualWithAccuracy(bone.positionZ, 0.0f, 0.001f, @"wrong position");
    
    // Test mesh
    GLLModelMesh *mesh = [model.meshes objectAtIndex:0];
    XCTAssertEqualObjects(mesh.name, @"1_mesh0_12", @"incorrect mesh name");
    XCTAssertEqual(mesh.countOfUVLayers, 0UL, @"Incorrect number of UV layers");
    XCTAssertEqual(mesh.countOfVertices, 24UL, @"Incorrect number of vertices for cube (with no sharing due to normals)");
    XCTAssertEqual(mesh.countOfElements, 36UL, @"Incorrect number of elements for cube");
}

- (void)test1Mesh2Bones
{
    GLLTestObjectWriter *writer = [[GLLTestObjectWriter alloc] init];
    writer.numBones = 2;
    writer.numMeshes = 1;
    [writer setRenderGroup:1 renderParameterValues:@[ @(12) ] forMesh:0];
    NSString *contents = writer.testFileString;
    XCTAssertNotNil(contents, @"Writer didn't write anything.");
    
    NSError *error = nil;
    GLLModel *model = [[GLLModel alloc] initASCIIFromString:contents baseURL:[NSURL fileURLWithPath:@"/var/tmp/generic_item.mesh.ascii"] parent:nil error:&error];
    XCTAssertNotNil(model, @"Couldn't read test object");
    XCTAssertNil(error, @"Produced error: %@", error);
    
    XCTAssertEqual(model.bones.count, 2UL, @"Should have two bones!");
    XCTAssertEqual(model.meshes.count, 1UL, @"Should have one mesh!");
    
    // Test bone
    GLLModelBone *bone = [model.bones objectAtIndex:0];
    XCTAssertEqualObjects(bone.name, @"bone0", @"incorrect name");
    XCTAssertNil(bone.parent, @"should not have a parent, has %@", bone.parent);
    XCTAssertEqualWithAccuracy(bone.positionX, 0.0f, 0.001f, @"wrong position");
    XCTAssertEqualWithAccuracy(bone.positionY, 0.0f, 0.001f, @"wrong position");
    XCTAssertEqualWithAccuracy(bone.positionZ, 0.0f, 0.001f, @"wrong position");
    
    bone = [model.bones objectAtIndex:1];
    XCTAssertEqualObjects(bone.name, @"bone1", @"incorrect name");
    XCTAssertEqualObjects(bone.parent, [model.bones objectAtIndex:0], @"should have previous as parent");
    XCTAssertEqualWithAccuracy(bone.positionX, 1.0f, 0.001f, @"wrong position");
    XCTAssertEqualWithAccuracy(bone.positionY, 0.0f, 0.001f, @"wrong position");
    XCTAssertEqualWithAccuracy(bone.positionZ, 0.0f, 0.001f, @"wrong position");
    
    // Test mesh
    GLLModelMesh *mesh = [model.meshes objectAtIndex:0];
    XCTAssertEqualObjects(mesh.name, @"1_mesh0_12", @"incorrect mesh name");
    XCTAssertEqual(mesh.countOfUVLayers, 0UL, @"Incorrect number of UV layers");
    XCTAssertEqual(mesh.countOfVertices, 40UL, @"Incorrect number of vertices for two joined cubes");
    XCTAssertEqual(mesh.countOfElements, 60UL, @"Incorrect number of elements for two joined cubes");
}

- (void)test1Bone2Meshes
{
    GLLTestObjectWriter *writer = [[GLLTestObjectWriter alloc] init];
    writer.numBones = 1;
    writer.numMeshes = 2;
    [writer setRenderGroup:1 renderParameterValues:@[ @(12) ] forMesh:0];
    [writer setRenderGroup:2 renderParameterValues:@[ @(24) ] forMesh:1];
    NSString *contents = writer.testFileString;
    XCTAssertNotNil(contents, @"Writer didn't write anything.");
    
    NSError *error = nil;
    GLLModel *model = [[GLLModel alloc] initASCIIFromString:contents baseURL:[NSURL fileURLWithPath:@"/var/tmp/generic_item.mesh.ascii"] parent:nil error:&error];
    XCTAssertNotNil(model, @"Couldn't read test object");
    XCTAssertNil(error, @"Produced error: %@", error);
    
    XCTAssertEqual(model.bones.count, 1UL, @"Should have one bone!");
    XCTAssertEqual(model.meshes.count, 2UL, @"Should have two meshes!");
    
    // Test bone
    GLLModelBone *bone = [model.bones objectAtIndex:0];
    XCTAssertEqualObjects(bone.name, @"bone0", @"incorrect name");
    XCTAssertNil(bone.parent, @"should not have a parent, has %@", bone.parent);
    XCTAssertEqualWithAccuracy(bone.positionX, 0.0f, 0.001f, @"wrong position");
    XCTAssertEqualWithAccuracy(bone.positionY, 0.0f, 0.001f, @"wrong position");
    XCTAssertEqualWithAccuracy(bone.positionZ, 0.0f, 0.001f, @"wrong position");
    
    // Test mesh
    GLLModelMesh *mesh = [model.meshes objectAtIndex:0];
    XCTAssertEqualObjects(mesh.name, @"1_mesh0_12", @"incorrect mesh name");
    XCTAssertEqual(mesh.countOfUVLayers, 0UL, @"Incorrect number of UV layers");
    XCTAssertEqual(mesh.countOfVertices, 20UL, @"Incorrect number of vertices for cube with one missing wall (with no sharing due to normals)");
    XCTAssertEqual(mesh.countOfElements, 30UL, @"Incorrect number of elements for cube with one missing wall");
    
    mesh = [model.meshes objectAtIndex:1];
    XCTAssertEqualObjects(mesh.name, @"2_mesh1_24", @"incorrect mesh name");
    XCTAssertEqual(mesh.countOfUVLayers, 0UL, @"Incorrect number of UV layers");
    XCTAssertEqual(mesh.countOfVertices, 20UL, @"Incorrect number of vertices for cube with one missing wall (with no sharing due to normals)");
    XCTAssertEqual(mesh.countOfElements, 30UL, @"Incorrect number of elements for cube with one missing wall");
}

- (void)test2BonesAndMeshes
{
    GLLTestObjectWriter *writer = [[GLLTestObjectWriter alloc] init];
    writer.numBones = 2;
    writer.numMeshes = 2;
    [writer setRenderGroup:1 renderParameterValues:@[ @(12) ] forMesh:0];
    [writer setRenderGroup:2 renderParameterValues:@[ @(24) ] forMesh:1];
    NSString *contents = writer.testFileString;
    XCTAssertNotNil(contents, @"Writer didn't write anything.");
    
    NSError *error = nil;
    GLLModel *model = [[GLLModel alloc] initASCIIFromString:contents baseURL:[NSURL fileURLWithPath:@"/var/tmp/generic_item.mesh.ascii"] parent:nil error:&error];
    XCTAssertNotNil(model, @"Couldn't read test object");
    XCTAssertNil(error, @"Produced error: %@", error);
    
    XCTAssertEqual(model.bones.count, 2UL, @"Should have two bones!");
    XCTAssertEqual(model.meshes.count, 2UL, @"Should have two meshes!");
    
    // Test bone
    GLLModelBone *bone = [model.bones objectAtIndex:0];
    XCTAssertEqualObjects(bone.name, @"bone0", @"incorrect name");
    XCTAssertNil(bone.parent, @"should not have a parent, has %@", bone.parent);
    XCTAssertEqualWithAccuracy(bone.positionX, 0.0f, 0.001f, @"wrong position");
    XCTAssertEqualWithAccuracy(bone.positionY, 0.0f, 0.001f, @"wrong position");
    XCTAssertEqualWithAccuracy(bone.positionZ, 0.0f, 0.001f, @"wrong position");
    
    bone = [model.bones objectAtIndex:1];
    XCTAssertEqualObjects(bone.name, @"bone1", @"incorrect name");
    XCTAssertEqualObjects(bone.parent, [model.bones objectAtIndex:0], @"should have previous as parent");
    XCTAssertEqualWithAccuracy(bone.positionX, 1.0f, 0.001f, @"wrong position");
    XCTAssertEqualWithAccuracy(bone.positionY, 0.0f, 0.001f, @"wrong position");
    XCTAssertEqualWithAccuracy(bone.positionZ, 0.0f, 0.001f, @"wrong position");
    
    // Test mesh
    GLLModelMesh *mesh = [model.meshes objectAtIndex:0];
    XCTAssertEqualObjects(mesh.name, @"1_mesh0_12", @"incorrect mesh name");
    XCTAssertEqual(mesh.countOfUVLayers, 0UL, @"Incorrect number of UV layers");
    XCTAssertEqual(mesh.countOfVertices, 20UL, @"Incorrect number of vertices for cube with one missing wall (with no sharing due to normals)");
    XCTAssertEqual(mesh.countOfElements, 30UL, @"Incorrect number of elements for cube with one missing wall");
    
    mesh = [model.meshes objectAtIndex:1];
    XCTAssertEqualObjects(mesh.name, @"2_mesh1_24", @"incorrect mesh name");
    XCTAssertEqual(mesh.countOfUVLayers, 0UL, @"Incorrect number of UV layers");
    XCTAssertEqual(mesh.countOfVertices, 20UL, @"Incorrect number of vertices for cube with one missing wall (with no sharing due to normals)");
    XCTAssertEqual(mesh.countOfElements, 30UL, @"Incorrect number of elements for cube with one missing wall");
}

@end
