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
#import "GLLModelObj.h"

@interface GLLTestObjectWriterTest ()

@property (nonatomic) NSURL *tmpDirectoryURL;

@end

@implementation GLLTestObjectWriterTest

- (void)setUp
{
	NSString *tmp = NSTemporaryDirectory();
	
	NSURL *tmpDirectoryURL = [NSURL fileURLWithPath:tmp isDirectory:YES];
	self.tmpDirectoryURL = [[tmpDirectoryURL URLByAppendingPathComponent:[[NSBundle mainBundle] bundleIdentifier]] URLByAppendingPathComponent:@"Test"];
	NSError *error = nil;
	BOOL hasDirectory = [[NSFileManager defaultManager] createDirectoryAtURL:self.tmpDirectoryURL withIntermediateDirectories:YES attributes:nil error:&error];
	
	XCTAssertTrue(hasDirectory, @"Directory not available. Error: %@.", error);
}

- (void)tearDown
{
	[[NSFileManager defaultManager] removeItemAtURL:self.tmpDirectoryURL error:NULL];
}

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

- (void)testSimpleOBJ
{
	GLLTestObjectWriter *writer = [[GLLTestObjectWriter alloc] init];
	writer.numBones = 1;
	writer.numMeshes = 1;
	[writer setRenderGroup:1 renderParameterValues:@[ @(12) ] forMesh:0];
	writer.mtlLibName = @"testSimple.mtl";
	NSString *contentsOBJ = writer.testFileStringOBJ;
	XCTAssertNotNil(contentsOBJ, @"Writer didn't write anything.");
	NSString *contentsMTL = writer.testFileStringMTL;
	XCTAssertNotNil(contentsOBJ, @"Writer didn't write anything.");
	
	[self writeString:contentsOBJ toTmpFile:@"testSimple.obj"];
	[self writeString:contentsMTL toTmpFile:@"testSimple.mtl"];
	
	NSError *error = nil;
	GLLModelObj *model = [[GLLModelObj alloc] initWithContentsOfURL:[self.tmpDirectoryURL URLByAppendingPathComponent:@"testSimple.obj"] error:&error];
	XCTAssertNotNil(model, @"Couldn't read test object");
	XCTAssertNil(error, @"Produced error: %@", error);
	
	XCTAssertEqual(model.bones.count, 1UL, @"Should have one bone!");
	XCTAssertEqual(model.meshes.count, 1UL, @"Should have one mesh!");
	
	// Test bone
	GLLModelBone *bone = [model.bones objectAtIndex:0];
	XCTAssertEqualObjects(bone.name, @"Root bone", @"incorrect name");
	XCTAssertNil(bone.parent, @"should not have a parent, has %@", bone.parent);
	XCTAssertEqualWithAccuracy(bone.positionX, 0.0f, 0.001f, @"wrong position");
	XCTAssertEqualWithAccuracy(bone.positionY, 0.0f, 0.001f, @"wrong position");
	XCTAssertEqualWithAccuracy(bone.positionZ, 0.0f, 0.001f, @"wrong position");
	
	// Test mesh
	GLLModelMesh *mesh = [model.meshes objectAtIndex:0];
	XCTAssertEqualObjects(mesh.name, @"Mesh 1", @"incorrect mesh name");
	XCTAssertEqual(mesh.countOfUVLayers, 1UL, @"Incorrect number of UV layers");
	XCTAssertEqual(mesh.countOfVertices, 24UL, @"Incorrect number of vertices for cube (with no sharing due to normals)");
	XCTAssertEqual(mesh.countOfElements, 36UL, @"Incorrect number of elements for cube");
}

#pragma mark - Helpers

- (void)writeString:(NSString *)string toTmpFile:(NSString *)filename;
{
	NSError *error = nil;
	NSURL *url = [self.tmpDirectoryURL URLByAppendingPathComponent:filename];
	BOOL result = [string writeToURL:url atomically:NO encoding:NSUTF8StringEncoding error:&error];
	XCTAssertTrue(result, @"Couldn't write test data");
	XCTAssertNil(error, @"Got error with test data: %@", error);
}

@end
