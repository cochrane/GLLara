//
//  GLLBasicASCIIModelTest.m
//  GLLara
//
//  Created by Torsten Kammer on 17.10.12.
//  Copyright (c) 2012 Torsten Kammer. All rights reserved.
//

#import "GLLBasicASCIIModelTest.h"

#import "GLLModel.h"
#import "GLLModelBone.h"
#import "GLLModelMesh.h"
#import "GLLVertexFormat.h"

@implementation GLLBasicASCIIModelTest

- (void)testEmptyFile
{
    NSString *string = @"0 0";
    
    NSURL *baseURL = [NSURL fileURLWithPath:@"/tmp/generic_item.mesh"];
    GLLModel *model = [[GLLModel alloc] initASCIIFromString:string baseURL:baseURL parent:nil error:NULL];
    XCTAssertNotNil(model, @"Model has to be loaded.");
    
    XCTAssertEqual(model.bones.count, (NSUInteger) 0, @"Model should have no bones.");
    XCTAssertEqual(model.meshes.count, (NSUInteger) 0, @"Model should have no meshes.");
}

- (void)testBone
{
    NSString *string = @"1 #bone count\n\
    Test\n\
    -1\n\
    0.0 0 0.0\n\
    0";
    NSURL *baseURL = [NSURL fileURLWithPath:@"/tmp/generic_item.mesh"];
    GLLModel *model = [[GLLModel alloc] initASCIIFromString:string baseURL:baseURL parent:nil error:NULL];
    XCTAssertNotNil(model, @"Model has to be loaded.");
    
    XCTAssertEqual(model.bones.count, (NSUInteger) 1, @"Model should have one bone.");
    XCTAssertEqual(model.meshes.count, (NSUInteger) 0, @"Model should have no meshes.");
    
    GLLModelBone *bone = model.bones[0];
    XCTAssertEqualObjects(bone.name, @"Test", @"Incorrect name of bone");
    XCTAssertEqual(bone.parentIndex, (NSUInteger) UINT16_MAX, @"Bone parent index should be invalid");
    XCTAssertNil(bone.parent, @"Bone should not have a parent");
    XCTAssertTrue(bone.children == nil || bone.children.count == 0, @"Bone should not have children");
    XCTAssertEqual(bone.positionX, 0.0f, @"incorrect position");
    XCTAssertEqual(bone.positionY, 0.0f, @"incorrect position");
    XCTAssertEqual(bone.positionZ, 0.0f, @"incorrect position");
}

- (void)testEmptyMesh
{
    NSString *string = @"0 #bone count\n\
    1\n\
    Test\n\
    0\n\
    0\n\
    0\n\
    0";
    GLLModel *model = [[GLLModel alloc] initASCIIFromString:string baseURL:nil parent:nil error:NULL];
    XCTAssertNotNil(model, @"Model has to be loaded.");
    
    XCTAssertEqual(model.bones.count, (NSUInteger) 0, @"Model should have no bones.");
    XCTAssertEqual(model.meshes.count, (NSUInteger) 1, @"Model should have one mesh.");
    
    GLLModelMesh *mesh = model.meshes[0];
    XCTAssertEqualObjects(mesh.name, @"Test", @"Incorrect name of mesh");
    XCTAssertTrue(mesh.textures == nil || mesh.textures.count == 0, @"Mesh should not have textures");
    XCTAssertEqual(mesh.countOfElements, (NSUInteger) 0, @"Mesh is not empty");
    XCTAssertEqual(mesh.countOfUVLayers, (NSUInteger) 0, @"Mesh is not empty");
    XCTAssertEqual(mesh.countOfVertices, (NSUInteger) 0, @"Mesh is not empty");
    
    XCTAssertEqual(mesh.vertexData.length, (NSUInteger) 0, @"Mesh is not empty");
    XCTAssertEqual(mesh.elementData.length, (NSUInteger) 0, @"Mesh is not empty");
}

- (void)testTypicalModel
{
    NSString *string = @"2 # bones\n\
    Bone1\n\
    -1\n\
    -0.50 0 0\n\
    \n\
    Bone2\n\
    0\n\
    0.50 0 0.0\n\
    \n\
    1 # the count of them meshes\n\
    Test\n\
    1 # uv layers\n\
    1 # textures\n\
    tex.tga\n\
    0\n\
    3 # num verts\n\
    -.5 0 0\n\
    0 0 1\n\
    255 0 0 255\n\
    0 0\n\
    0 0 0 0\n\
    1 0 0 0\n\
    0.5 0 0\n\
    0 0 1\n\
    0 255 0  255\n\
    1 0\n\
    1 0 0 0\n\
    1 0 0 0\n\
    0.0 1.000000 0\n\
    0 0 1\n\
    0 0 255 255\n\
    0 1\n\
    0 1 0 0\n\
    0.5 0.5 0 0\n\
    1 # count of tris\n\
    0 1 2	";
    NSURL *baseURL = [NSURL fileURLWithPath:@"/tmp/generic_item.mesh"];
    GLLModel *model = [[GLLModel alloc] initASCIIFromString:string baseURL:baseURL parent:nil error:NULL];
    XCTAssertNotNil(model, @"Model has to be loaded.");
    
    XCTAssertEqual(model.bones.count, (NSUInteger) 2, @"Model should have two bones.");
    XCTAssertEqual(model.meshes.count, (NSUInteger) 1, @"Model should have one mesh.");
    
    GLLModelBone *bone1 = model.bones[0];
    GLLModelBone *bone2 = model.bones[1];
    XCTAssertEqualObjects(bone1.name, @"Bone1", @"Incorrect name of bone");
    XCTAssertEqual(bone1.parentIndex, (NSUInteger) UINT16_MAX, @"Bone parent index should be invalid");
    XCTAssertNil(bone1.parent, @"Bone should not have a parent");
    XCTAssertEqual(bone1.children.count, 1UL, @"Bone should not have children");
    XCTAssertEqualObjects(bone1.children, @[ bone2 ], @"bone 2 should be child of bone 1");
    XCTAssertEqual(bone1.positionX, -0.5f, @"incorrect position");
    XCTAssertEqual(bone1.positionY, 0.0f, @"incorrect position");
    XCTAssertEqual(bone1.positionZ, 0.0f, @"incorrect position");
    
    XCTAssertEqualObjects(bone2.name, @"Bone2", @"Incorrect name of bone");
    XCTAssertEqual(bone2.parentIndex, (NSUInteger) 0, @"Bone parent index should be 0");
    XCTAssertEqualObjects(bone2.parent, bone1, @"bone 2 should have bone 1 as parent");
    XCTAssertTrue(bone2.children == nil || bone2.children.count == 0, @"Bone 2 should not have children");
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
    XCTAssertEqual(mesh.vertexFormat.stride, (NSUInteger) 76, @"Wrong stride");
    XCTAssertEqual(mesh.vertexFormat.offsetForPosition, (NSUInteger) 0, @"Wrong offset");
    XCTAssertEqual(mesh.vertexFormat.offsetForNormal, (NSUInteger) 12, @"Wrong offset");
    XCTAssertEqual(mesh.vertexFormat.offsetForColor, (NSUInteger) 24, @"Wrong offset");
    XCTAssertEqual([mesh.vertexFormat offsetForTexCoordLayer:0], (NSUInteger) 28, @"Wrong offset");
    XCTAssertEqual([mesh.vertexFormat offsetForTangentLayer:0], (NSUInteger) 36, @"Wrong offset");
    
    const uint32_t *elements = mesh.elementData.bytes;
    XCTAssertTrue(memcmp(elements, (const uint32_t []) { 0, 1, 2 }, sizeof(uint32_t [3])) == 0, @"incorrect indices");
    
    const void *vertices = mesh.vertexData.bytes;
    XCTAssertTrue(memcmp(vertices + mesh.vertexFormat.stride*0 + mesh.vertexFormat.offsetForPosition,
                         (float [3]) { -0.5, 0.0, 0.0 },
                         sizeof(float [3])) == 0,
                  @"Vertex position 0");
    XCTAssertTrue(memcmp(vertices + mesh.vertexFormat.stride*1 + mesh.vertexFormat.offsetForPosition,
                         (float [3]) { 0.5, 0.0, 0.0 },
                         sizeof(float [3])) == 0,
                  @"Vertex position 1");
    XCTAssertTrue(memcmp(vertices + mesh.vertexFormat.stride*2 + mesh.vertexFormat.offsetForPosition,
                         (float [3]) { 0.0, 1.0, 0.0 },
                         sizeof(float [3])) == 0,
                  @"Vertex position 2");
}

- (void)testFilledMesh
{
    NSString *string = @"0\n\
    1 # the count of them meshes\n\
    Test\n\
    1 # uv layers\n\
    1 # textures\n\
    tex.tga\n\
    0\n\
    3 # num verts\n\
    -.5 0 0\n\
    0 0 1\n\
    255 0 0 255\n\
    0 0\n\
    0.5 0 0\n\
    0 0 1\n\
    0 255 0  255\n\
    1 0\n\
    0.0 1.000000 0\n\
    0 0 1\n\
    0 0 255 255\n\
    0 1\n\
    1 # count of tris\n\
    0 1 2	";
    NSURL *baseURL = [NSURL fileURLWithPath:@"/tmp/generic_item.mesh"];
    GLLModel *model = [[GLLModel alloc] initASCIIFromString:string baseURL:baseURL parent:nil error:NULL];
    XCTAssertNotNil(model, @"Model has to be loaded.");
    
    XCTAssertEqual(model.bones.count, (NSUInteger) 0, @"Model should have no bones.");
    XCTAssertEqual(model.meshes.count, (NSUInteger) 1, @"Model should have one mesh.");
    
    GLLModelMesh *mesh = model.meshes[0];
    XCTAssertEqualObjects(mesh.name, @"Test", @"Incorrect name of mesh");
    XCTAssertEqual(mesh.textures.count, (NSUInteger) 1, @"Mesh should have textures");
    XCTAssertEqualObjects([mesh.textures[0] absoluteURL], [NSURL fileURLWithPath:@"/tmp/tex.tga"], @"Incorrect URL");
    XCTAssertEqual(mesh.countOfElements, (NSUInteger) 3, @"Not enough indices");
    XCTAssertEqual(mesh.countOfUVLayers, (NSUInteger) 1, @"Not enough UV layers");
    XCTAssertEqual(mesh.countOfVertices, (NSUInteger) 3, @"Not enough vertices");
    
    XCTAssertEqual(mesh.vertexData.length, (NSUInteger) 156, @"Vertex data count wrong");
    XCTAssertEqual(mesh.elementData.length, (NSUInteger) 12, @"Element data count wrong");
    XCTAssertEqual(mesh.vertexFormat.stride, (NSUInteger) 52, @"Wrong stride");
    XCTAssertEqual(mesh.vertexFormat.offsetForPosition, (NSUInteger) 0, @"Wrong offset");
    XCTAssertEqual(mesh.vertexFormat.offsetForNormal, (NSUInteger) 12, @"Wrong offset");
    XCTAssertEqual(mesh.vertexFormat.offsetForColor, (NSUInteger) 24, @"Wrong offset");
    XCTAssertEqual([mesh.vertexFormat offsetForTexCoordLayer:0], (NSUInteger) 28, @"Wrong offset");
    XCTAssertEqual([mesh.vertexFormat offsetForTangentLayer:0], (NSUInteger) 36, @"Wrong offset");
    
    const uint32_t *elements = mesh.elementData.bytes;
    XCTAssertTrue(memcmp(elements, (const uint32_t []) { 0, 1, 2 }, sizeof(uint32_t [3])) == 0, @"incorrect indices");
    
    const void *vertices = mesh.vertexData.bytes;
    XCTAssertTrue(memcmp(vertices + mesh.vertexFormat.stride*0 + mesh.vertexFormat.offsetForPosition,
                         (float [3]) { -0.5, 0.0, 0.0 },
                         sizeof(float [3])) == 0,
                  @"Vertex position 0");
    XCTAssertTrue(memcmp(vertices + mesh.vertexFormat.stride*1 + mesh.vertexFormat.offsetForPosition,
                         (float [3]) { 0.5, 0.0, 0.0 },
                         sizeof(float [3])) == 0,
                  @"Vertex position 1");
    XCTAssertTrue(memcmp(vertices + mesh.vertexFormat.stride*2 + mesh.vertexFormat.offsetForPosition,
                         (float [3]) { 0.0, 1.0, 0.0 },
                         sizeof(float [3])) == 0,
                  @"Vertex position 2");
}

@end
