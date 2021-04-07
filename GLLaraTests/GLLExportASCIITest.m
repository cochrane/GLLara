//
//  GLLExportASCIITest.m
//  GLLara
//
//  Created by Torsten Kammer on 27.10.12.
//  Copyright (c) 2012 Torsten Kammer. All rights reserved.
//

#import "GLLExportASCIITest.h"

#import "GLLItem.h"
#import "GLLItem+MeshExport.h"
#import "GLLModel.h"
#import "GLLModelBone.h"
#import "GLLModelMesh.h"

@implementation GLLExportASCIITest

- (void)setUp
{
    NSError *error = nil;
    self.coordinator = [[NSPersistentStoreCoordinator alloc] initWithManagedObjectModel:[NSManagedObjectModel mergedModelFromBundles:nil]];
    NSPersistentStore *inMemoryStore = [self.coordinator addPersistentStoreWithType:NSInMemoryStoreType configuration:nil URL:nil options:nil error:&error];
    STAssertNotNil(inMemoryStore, @"Couldn't create store: %@", error);
    self.managedObjectContext = [[NSManagedObjectContext alloc] init];
    self.managedObjectContext.persistentStoreCoordinator = self.coordinator;
}

- (void)tearDown
{
    self.coordinator = nil;
    self.managedObjectContext = nil;
}

- (void)testASCIIFromASCII
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
    32_Test_1\n\
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
    GLLModel *originalModel = [[GLLModel alloc] initASCIIFromString:string baseURL:baseURL parent:nil error:NULL];
    
    GLLItem *newItem = [NSEntityDescription insertNewObjectForEntityForName:@"GLLItem" inManagedObjectContext:self.managedObjectContext];
    newItem.model = originalModel;
    
    NSError *error = nil;
    NSString *exported = [newItem writeASCIIError:&error];
    STAssertNotNil(exported, @"Should have written something");
    STAssertNil(error, @"Should not be an error, is %@", error);
    GLLModel *model = [[GLLModel alloc] initASCIIFromString:exported baseURL:baseURL parent:nil error:&error];
    STAssertNotNil(model, @"Model has to be loaded.");
    STAssertNil(error, @"Should not be an error, is %@", error);
    if (!model) return;
    
    STAssertEquals(model.bones.count, (NSUInteger) 2, @"Model should have two bones.");
    STAssertEquals(model.meshes.count, (NSUInteger) 1, @"Model should have one mesh.");
    
    GLLModelBone *bone1 = model.bones[0];
    GLLModelBone *bone2 = model.bones[1];
    STAssertEqualObjects(bone1.name, @"Bone1", @"Incorrect name of bone");
    STAssertEquals(bone1.parentIndex, (NSUInteger) UINT16_MAX, @"Bone parent index should be invalid");
    STAssertNil(bone1.parent, @"Bone should not have a parent");
    STAssertEquals(bone1.children.count, 1UL, @"Bone should not have children");
    STAssertEqualObjects(bone1.children, @[ bone2 ], @"bone 2 should be child of bone 1");
    STAssertEquals(bone1.positionX, -0.5f, @"incorrect position");
    STAssertEquals(bone1.positionY, 0.0f, @"incorrect position");
    STAssertEquals(bone1.positionZ, 0.0f, @"incorrect position");
    
    STAssertEqualObjects(bone2.name, @"Bone2", @"Incorrect name of bone");
    STAssertEquals(bone2.parentIndex, (NSUInteger) 0, @"Bone parent index should be 0");
    STAssertEqualObjects(bone2.parent, bone1, @"bone 2 should have bone 1 as parent");
    STAssertTrue(bone2.children == nil || bone2.children.count == 0, @"Bone 2 should not have children");
    STAssertEquals(bone2.positionX, 0.5f, @"incorrect position");
    STAssertEquals(bone2.positionY, 0.0f, @"incorrect position");
    STAssertEquals(bone2.positionZ, 0.0f, @"incorrect position");
    
    GLLModelMesh *mesh = model.meshes[0];
    STAssertEqualObjects(mesh.displayName, @"Test", @"Incorrect name of mesh");
    STAssertEquals(mesh.textures.count, (NSUInteger) 1, @"Mesh should have textures");
    STAssertEqualObjects([mesh.textures[0] absoluteURL], [NSURL fileURLWithPath:@"/tmp/tex.tga"], @"Incorrect URL");
    STAssertEquals(mesh.countOfElements, (NSUInteger) 3, @"Not enough indices");
    STAssertEquals(mesh.countOfUVLayers, (NSUInteger) 1, @"Not enough UV layers");
    STAssertEquals(mesh.countOfVertices, (NSUInteger) 3, @"Not enough vertices");
    
    STAssertEquals(mesh.vertexData.length, (NSUInteger) 228, @"Vertex data count wrong");
    STAssertEquals(mesh.elementData.length, (NSUInteger) 12, @"Element data count wrong");
    STAssertEquals(mesh.stride, (NSUInteger) 76, @"Wrong stride");
    
    const uint32_t *elements = mesh.elementData.bytes;
    STAssertTrue(memcmp(elements, (const uint32_t []) { 0, 1, 2 }, sizeof(uint32_t [3])) == 0, @"incorrect indices");
}

- (void)testASCIIFromBinary
{
    uint8_t bytes[] = { 0x02, 0x00, 0x00, 0x00, // Bone count
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
        0x09, '3', '2', '_', 'T', 'e', 's', 't', '_',  '1', // Name
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
        0x00, 0x00, 0x00, 0x00, // tangent
        0x00, 0x00, 0x00, 0x00,
        0x00, 0x00, 0x00, 0x00,
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
        0x00, 0x00, 0x00, 0x00, // tangent
        0x00, 0x00, 0x00, 0x00,
        0x00, 0x00, 0x00, 0x00,
        0x00, 0x00, 0x00, 0x00,
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
        0x00, 0x00, 0x00, 0x00, // tangent
        0x00, 0x00, 0x00, 0x00,
        0x00, 0x00, 0x00, 0x00,
        0x00, 0x00, 0x00, 0x00,
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
    
    GLLModel *originalModel = [[GLLModel alloc] initBinaryFromData:data baseURL:baseURL parent:nil error:NULL];
    
    GLLItem *newItem = [NSEntityDescription insertNewObjectForEntityForName:@"GLLItem" inManagedObjectContext:self.managedObjectContext];
    newItem.model = originalModel;
    
    NSError *error = nil;
    NSString *exported = [newItem writeASCIIError:&error];
    STAssertNotNil(exported, @"Should have written something");
    STAssertNil(error, @"Should not be an error, is %@", error);
    GLLModel *model = [[GLLModel alloc] initASCIIFromString:exported baseURL:baseURL parent:nil error:&error];
    STAssertNotNil(model, @"Model has to be loaded.");
    STAssertNil(error, @"Should not be an error, is %@", error);
    if (!model) return;
    
    STAssertEquals(model.bones.count, (NSUInteger) 2, @"Model should have two bones.");
    STAssertEquals(model.meshes.count, (NSUInteger) 1, @"Model should have one mesh.");
    
    GLLModelBone *bone1 = model.bones[0];
    GLLModelBone *bone2 = model.bones[1];
    STAssertEqualObjects(bone1.name, @"Bone1", @"Incorrect name of bone");
    STAssertEquals(bone1.parentIndex, (NSUInteger) UINT16_MAX, @"Bone parent index should be invalid");
    STAssertNil(bone1.parent, @"Bone should not have a parent");
    STAssertEquals(bone1.children.count, 1UL, @"Bone should not have children");
    STAssertEqualObjects(bone1.children, @[ bone2 ], @"bone 2 should be child of bone 1");
    STAssertEquals(bone1.positionX, -0.5f, @"incorrect position");
    STAssertEquals(bone1.positionY, 0.0f, @"incorrect position");
    STAssertEquals(bone1.positionZ, 0.0f, @"incorrect position");
    
    STAssertEqualObjects(bone2.name, @"Bone2", @"Incorrect name of bone");
    STAssertEquals(bone2.parentIndex, (NSUInteger) 0, @"Bone parent index should be 0");
    STAssertEqualObjects(bone2.parent, bone1, @"bone 2 should have bone 1 as parent");
    STAssertTrue(bone2.children == nil || bone2.children.count == 0, @"Bone 2 should not have children");
    STAssertEquals(bone2.positionX, 0.5f, @"incorrect position");
    STAssertEquals(bone2.positionY, 0.0f, @"incorrect position");
    STAssertEquals(bone2.positionZ, 0.0f, @"incorrect position");
    
    GLLModelMesh *mesh = model.meshes[0];
    STAssertEqualObjects(mesh.displayName, @"Test", @"Incorrect name of mesh");
    STAssertEquals(mesh.textures.count, (NSUInteger) 1, @"Mesh should have textures");
    STAssertEqualObjects([mesh.textures[0] absoluteURL], [NSURL fileURLWithPath:@"/tmp/tex.tga"], @"Incorrect URL");
    STAssertEquals(mesh.countOfElements, (NSUInteger) 3, @"Not enough indices");
    STAssertEquals(mesh.countOfUVLayers, (NSUInteger) 1, @"Not enough UV layers");
    STAssertEquals(mesh.countOfVertices, (NSUInteger) 3, @"Not enough vertices");
    
    STAssertEquals(mesh.vertexData.length, (NSUInteger) 228, @"Vertex data count wrong");
    STAssertEquals(mesh.elementData.length, (NSUInteger) 12, @"Element data count wrong");
    STAssertEquals(mesh.stride, (NSUInteger) 76, @"Wrong stride");
    
    const uint32_t *elements = mesh.elementData.bytes;
    STAssertTrue(memcmp(elements, (const uint32_t []) { 0, 1, 2 }, sizeof(uint32_t [3])) == 0, @"incorrect indices");
}

@end
