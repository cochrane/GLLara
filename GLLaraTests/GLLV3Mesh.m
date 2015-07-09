//
//  GLLV3Mesh.m
//  GLLara
//
//  Created by Torsten Kammer on 02.02.13.
//  Copyright (c) 2013 Torsten Kammer. All rights reserved.
//

#import "GLLV3Mesh.h"

#import "GLLModel.h"
#import "GLLModelBone.h"
#import "GLLModelMesh.h"

@implementation GLLV3Mesh

- (void)testFilledMesh
{
	uint8_t bytes[] = {
		0xA0, 0xEE, 0x04, 0x00, // Version 2 magic number
		0x02, 0x00, 0x0F, 0x00, // Major and minor version(?)
		0x00, // Creator (?)
		0x00, 0x00, 0x00, 0x00, // Extra data (?)
		0x00, 0x00, 0x00, // Extra strings (?)
		
		
		0x00, 0x00, 0x00, 0x00, // Bone count
		
		0x01, 0x00, 0x00, 0x00, // Count of meshes
		0x04, 'T', 'e', 's', 't', // Name
		0x01, 0x00, 0x00, 0x00, // Count of UV layers
		0x01, 0x00, 0x00, 0x00, // Count of textures
		0x07, 't', 'e', 'x', '.', 't', 'g', 'a', // tex name 1
		0x00, 0x00, 0x00, 0x00, // tex uv layer 1 (ignored)
		0x03, 0x00, 0x00, 0x00, // Count of vertices.
		0x00, 0x00, 0x00, 0xBF, // position 0
		0x00, 0x00, 0x00, 0x00,
		0x00, 0x00, 0x00, 0x00,
		0x00, 0x00, 0x00, 0x00, // normal
		0x00, 0x00, 0x00, 0x00,
		0x00, 0x00, 0x80, 0x3F,
		0xFF, 0x00, 0x00, 0xFF, // color
		0x00, 0x00, 0x00, 0x00, // tex coord
		0x00, 0x00, 0x00, 0x00,
		0x00, 0x00, 0x00, 0x3F, // position 1
		0x00, 0x00, 0x00, 0x00,
		0x00, 0x00, 0x00, 0x00,
		0x00, 0x00, 0x00, 0x00, // normal
		0x00, 0x00, 0x00, 0x00,
		0x00, 0x00, 0x80, 0x3F,
		0x00, 0xFF, 0x00, 0xFF, // color
		0x00, 0x00, 0x00, 0x3F, // tex coord
		0x00, 0x00, 0x80, 0x3F,
		0x00, 0x00, 0x00, 0x00, // position 2
		0x00, 0x00, 0x80, 0x3F,
		0x00, 0x00, 0x00, 0x00,
		0x00, 0x00, 0x00, 0x00, // normal
		0x00, 0x00, 0x00, 0x00,
		0x00, 0x00, 0x80, 0x3F,
		0x00, 0x00, 0xFF, 0xFF, // color
		0x00, 0x00, 0x00, 0x00, // tex coord
		0x00, 0x00, 0x80, 0x3F,
		0x01, 0x00, 0x00, 0x00, // Count of triangles
		0x00, 0x00, 0x00, 0x00, // index 1
		0x01, 0x00, 0x00, 0x00, // index 2
		0x02, 0x00, 0x00, 0x00, // index 3
	};
	NSData *data = [NSData dataWithBytes:bytes length:sizeof(bytes)];
	NSURL *baseURL = [NSURL fileURLWithPath:@"/tmp/generic_item.mesh"];
	
	NSError *error = nil;
	GLLModel *model = [[GLLModel alloc] initBinaryFromData:data baseURL:baseURL parent:nil error:&error];
    XCTAssertNotNil(model, @"Model has to be loaded.");
    XCTAssertNil(error, @"Should be no error (got %@)", error);
	
	XCTAssertEqual(model.bones.count, (NSUInteger) 0, @"Model should have no bones.");
	XCTAssertEqual(model.meshes.count, (NSUInteger) 1, @"Model should have one mesh.");
	
	GLLModelMesh *mesh = model.meshes[0];
	XCTAssertEqualObjects(mesh.name, @"Test", @"Incorrect name of mesh");
	XCTAssertEqual(mesh.textures.count, (NSUInteger) 1, @"Mesh should have textures");
	XCTAssertEqualObjects([mesh.textures[0] absoluteURL], [NSURL fileURLWithPath:@"/tmp/tex.tga"], @"Incorrect URL");
	XCTAssertEqual(mesh.countOfElements, (NSUInteger) 3, @"Not enough indices");
	XCTAssertEqual(mesh.countOfUVLayers, (NSUInteger) 1, @"Not enough UV layers");
	XCTAssertEqual(mesh.countOfVertices, (NSUInteger) 3, @"Not enough vertices");
	
	XCTAssertEqual(mesh.vertexData.length, (NSUInteger) 108, @"Vertex data count wrong");
	XCTAssertEqual(mesh.elementData.length, (NSUInteger) 12, @"Element data count wrong");
	XCTAssertEqual(mesh.stride, (NSUInteger) 36, @"Wrong stride");
	XCTAssertEqual(mesh.offsetForPosition, (NSUInteger) 0, @"Wrong offset");
	XCTAssertEqual(mesh.offsetForNormal, (NSUInteger) 12, @"Wrong offset");
	XCTAssertEqual(mesh.offsetForColor, (NSUInteger) 24, @"Wrong offset");
	XCTAssertEqual([mesh offsetForTexCoordLayer:0], (NSUInteger) 28, @"Wrong offset");
	XCTAssertFalse(mesh.hasTangents, @"Mesh has no tangents");
	
	const uint32_t *elements = mesh.elementData.bytes;
	XCTAssertTrue(memcmp(elements, (const uint32_t []) { 0, 1, 2 }, sizeof(uint32_t [3])) == 0, @"incorrect indices");
	
	const void *vertices = mesh.vertexData.bytes;
	XCTAssertTrue(memcmp(vertices + mesh.stride*0 + mesh.offsetForPosition,
						(float [3]) { -0.5, 0.0, 0.0 },
						sizeof(float [3])) == 0,
				 @"Vertex position 0");
	XCTAssertTrue(memcmp(vertices + mesh.stride*1 + mesh.offsetForPosition,
						(float [3]) { 0.5, 0.0, 0.0 },
						sizeof(float [3])) == 0,
				 @"Vertex position 1");
	XCTAssertTrue(memcmp(vertices + mesh.stride*2 + mesh.offsetForPosition,
						(float [3]) { 0.0, 1.0, 0.0 },
						sizeof(float [3])) == 0,
				 @"Vertex position 2");
}

- (void)testTypicalModel
{
	uint8_t bytes[] = {
		0xA0, 0xEE, 0x04, 0x00, // Version 2 magic number
		0x02, 0x00, 0x0F, 0x00, // Major and minor version(?)
		0x00, // Creator (?)
		0x00, 0x00, 0x00, 0x00, // Extra data (?)
		0x00, 0x00, 0x00, // Extra strings (?)
		
		0x02, 0x00, 0x00, 0x00, // Bone count
		0x05, 'B', 'o', 'n', 'e', '1', // Name
		0xFF, 0xFF, // Parent index
		0x00, 0x00, 0x00, 0xBF, // Position X
		0x00, 0x00, 0x00, 0x00, // Position Y
		0x00, 0x00, 0x00, 0x00, // Position Z
		0x05, 'B', 'o', 'n', 'e', '2', // Name
		0x00, 0x00, // Parent index
		0x00, 0x00, 0x00, 0x3F, // Position X
		0x00, 0x00, 0x00, 0x00, // Position Y
		0x00, 0x00, 0x00, 0x00, // Position Z
		
		0x01, 0x00, 0x00, 0x00, // Count of meshes
		0x04, 'T', 'e', 's', 't', // Name
		0x01, 0x00, 0x00, 0x00, // Count of UV layers
		0x01, 0x00, 0x00, 0x00, // Count of textures
		0x07, 't', 'e', 'x', '.', 't', 'g', 'a', // tex name 1
		0x00, 0x00, 0x00, 0x00, // tex uv layer 1 (ignored)
		0x03, 0x00, 0x00, 0x00, // Count of vertices.
		0x00, 0x00, 0x00, 0xBF, // position 0
		0x00, 0x00, 0x00, 0x00,
		0x00, 0x00, 0x00, 0x00,
		0x00, 0x00, 0x00, 0x00, // normal
		0x00, 0x00, 0x00, 0x00,
		0x00, 0x00, 0x80, 0x3F,
		0xFF, 0x00, 0x00, 0xFF, // color
		0x00, 0x00, 0x00, 0x00, // tex coord
		0x00, 0x00, 0x00, 0x00,
		0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, // bone indices
		0x00, 0x00, 0x80, 0x3F, // bone weights
		0x00, 0x00, 0x00, 0x00,
		0x00, 0x00, 0x00, 0x00,
		0x00, 0x00, 0x00, 0x00,
		0x00, 0x00, 0x00, 0x3F, // position 1
		0x00, 0x00, 0x00, 0x00,
		0x00, 0x00, 0x00, 0x00,
		0x00, 0x00, 0x00, 0x00, // normal
		0x00, 0x00, 0x00, 0x00,
		0x00, 0x00, 0x80, 0x3F,
		0x00, 0xFF, 0x00, 0xFF, // color
		0x00, 0x00, 0x00, 0x3F, // tex coord
		0x00, 0x00, 0x80, 0x3F,
		0x01, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, // bone indices
		0x00, 0x00, 0x80, 0x3F, // bone weights
		0x00, 0x00, 0x00, 0x00,
		0x00, 0x00, 0x00, 0x00,
		0x00, 0x00, 0x00, 0x00,
		0x00, 0x00, 0x00, 0x00, // position 2
		0x00, 0x00, 0x80, 0x3F,
		0x00, 0x00, 0x00, 0x00,
		0x00, 0x00, 0x00, 0x00, // normal
		0x00, 0x00, 0x00, 0x00,
		0x00, 0x00, 0x80, 0x3F,
		0x00, 0x00, 0xFF, 0xFF, // color
		0x00, 0x00, 0x00, 0x00, // tex coord
		0x00, 0x00, 0x80, 0x3F,
		0x00, 0x00, 0x01, 0x00, 0x00, 0x00, 0x00, 0x00, // bone indices
		0x00, 0x00, 0x00, 0x3F, // bone weights
		0x00, 0x00, 0x00, 0x3F,
		0x00, 0x00, 0x00, 0x00,
		0x00, 0x00, 0x00, 0x00,
		0x01, 0x00, 0x00, 0x00, // Count of triangles
		0x00, 0x00, 0x00, 0x00, // index 1
		0x01, 0x00, 0x00, 0x00, // index 2
		0x02, 0x00, 0x00, 0x00, // index 3
	};
	NSData *data = [NSData dataWithBytes:bytes length:sizeof(bytes)];
	NSURL *baseURL = [NSURL fileURLWithPath:@"/tmp/generic_item.mesh"];
	
	NSError *error = nil;
	GLLModel *model = [[GLLModel alloc] initBinaryFromData:data baseURL:baseURL parent:nil error:&error];
	XCTAssertNotNil(model, @"Model has to be loaded.");
	XCTAssertNil(error, @"Should be no error, but is %@", error);
	
	XCTAssertEqual(model.bones.count, (NSUInteger) 2, @"Model should have two bones.");
	XCTAssertEqual(model.meshes.count, (NSUInteger) 1, @"Model should have one mesh.");
	
	GLLModelBone *bone1 = model.bones[0];
	GLLModelBone *bone2 = model.bones[1];
	XCTAssertEqualObjects(bone1.name, @"Bone1", @"Incorrect name of bone");
	XCTAssertEqual(bone1.parentIndex, (NSUInteger) UINT16_MAX, @"Bone parent index should be invalid");
	XCTAssertNil([model parentForBone:bone1], @"Bone should not have a parent");
    NSArray *bone1Children = [model childrenForBone:bone1];
	XCTAssertEqual(bone1Children.count, 1UL, @"Bone should not have children");
	XCTAssertEqualObjects(bone1Children, @[ bone2 ], @"bone 2 should be child of bone 1");
	XCTAssertEqual(bone1.positionX, -0.5f, @"incorrect position");
	XCTAssertEqual(bone1.positionY, 0.0f, @"incorrect position");
	XCTAssertEqual(bone1.positionZ, 0.0f, @"incorrect position");
	
	XCTAssertEqualObjects(bone2.name, @"Bone2", @"Incorrect name of bone");
	XCTAssertEqual(bone2.parentIndex, (NSUInteger) 0, @"Bone parent index should be 0");
	XCTAssertEqualObjects([model parentForBone:bone2], bone1, @"bone 2 should have bone 1 as parent");
    NSArray *bone2Children = [model childrenForBone:bone2];
	XCTAssertTrue(bone2Children == nil || bone2Children.count == 0, @"Bone 2 should not have children");
	XCTAssertEqual(bone2.positionX, 0.5f, @"incorrect position");
	XCTAssertEqual(bone2.positionY, 0.0f, @"incorrect position");
	XCTAssertEqual(bone2.positionZ, 0.0f, @"incorrect position");
	
	GLLModelMesh *mesh = model.meshes[0];
	XCTAssertEqualObjects(mesh.name, @"Test", @"Incorrect name of mesh");
	XCTAssertEqual(mesh.textures.count, (NSUInteger) 1, @"Mesh should have textures");
	XCTAssertEqualObjects([mesh.textures[0] absoluteURL], [NSURL fileURLWithPath:@"/tmp/tex.tga"], @"Incorrect URL");
	XCTAssertEqual(mesh.countOfElements, (NSUInteger) 3, @"Not enough indices");
	XCTAssertEqual(mesh.countOfUVLayers, (NSUInteger) 1, @"Not enough UV layers");
	XCTAssertEqual(mesh.countOfVertices, (NSUInteger) 3, @"Not enough vertices");
	
	XCTAssertEqual(mesh.vertexData.length, (NSUInteger) 228, @"Vertex data count wrong");
	XCTAssertEqual(mesh.elementData.length, (NSUInteger) 12, @"Element data count wrong");
	XCTAssertEqual(mesh.stride, (NSUInteger) 76, @"Wrong stride");
	XCTAssertEqual(mesh.offsetForPosition, (NSUInteger) 0, @"Wrong offset");
	XCTAssertEqual(mesh.offsetForNormal, (NSUInteger) 12, @"Wrong offset");
	XCTAssertEqual(mesh.offsetForColor, (NSUInteger) 24, @"Wrong offset");
	XCTAssertEqual([mesh offsetForTexCoordLayer:0], (NSUInteger) 28, @"Wrong offset");
	XCTAssertEqual(mesh.offsetForBoneIndices, (NSUInteger) 52, @"Wrong offset");
	XCTAssertEqual(mesh.offsetForBoneWeights, (NSUInteger) 60, @"Wrong offset");
	
	const uint32_t *elements = mesh.elementData.bytes;
	XCTAssertTrue(memcmp(elements, (const uint32_t []) { 0, 1, 2 }, sizeof(uint32_t [3])) == 0, @"incorrect indices");
	
	const void *vertices = mesh.vertexData.bytes;
	XCTAssertTrue(memcmp(vertices + mesh.stride*0 + mesh.offsetForPosition,
						(float [3]) { -0.5, 0.0, 0.0 },
						sizeof(float [3])) == 0,
				 @"Vertex position 0");
	XCTAssertTrue(memcmp(vertices + mesh.stride*1 + mesh.offsetForPosition,
						(float [3]) { 0.5, 0.0, 0.0 },
						sizeof(float [3])) == 0,
				 @"Vertex position 1");
	XCTAssertTrue(memcmp(vertices + mesh.stride*2 + mesh.offsetForPosition,
						(float [3]) { 0.0, 1.0, 0.0 },
						sizeof(float [3])) == 0,
				 @"Vertex position 2");
}


@end
