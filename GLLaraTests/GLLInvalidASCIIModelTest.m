//
//  GLLInvalidASCIIModelTest.m
//  GLLara
//
//  Created by Torsten Kammer on 19.10.12.
//  Copyright (c) 2012 Torsten Kammer. All rights reserved.
//

#import "GLLInvalidASCIIModelTest.h"

#import "GLLModel.h"

@implementation GLLInvalidASCIIModelTest

- (void)testZeroLengthFile
{
    NSString *source = @"";
    NSURL *baseURL = [NSURL fileURLWithPath:@"/tmp/generic_item.mesh"];
    
    GLLModel *model;
    NSError *error = nil;
    XCTAssertNoThrow(model = [[GLLModel alloc] initASCIIFromString:source baseURL:baseURL parent:nil error:&error], @"Loading should never throw");
    XCTAssertNil(model, @"This model should not have loaded");
    XCTAssertNotNil(error, @"Model should have written an error message");
}

- (void)testTooManyBonesFile
{
    NSString *source = @"12 0";
    NSURL *baseURL = [NSURL fileURLWithPath:@"/tmp/generic_item.mesh"];
    
    GLLModel *model;
    NSError *error = nil;
    XCTAssertNoThrow(model = [[GLLModel alloc] initASCIIFromString:source baseURL:baseURL parent:nil error:&error], @"Loading should never throw");
    XCTAssertNil(model, @"This model should not have loaded");
    XCTAssertNotNil(error, @"Model should have written an error message");
}

- (void)testTooManyMeshesFile
{
    NSString *source = @"0 12";
    NSURL *baseURL = [NSURL fileURLWithPath:@"/tmp/generic_item.mesh"];
    
    GLLModel *model;
    NSError *error = nil;
    XCTAssertNoThrow(model = [[GLLModel alloc] initASCIIFromString:source baseURL:baseURL parent:nil error:&error], @"Loading should never throw");
    XCTAssertNil(model, @"This model should not have loaded");
    XCTAssertNotNil(error, @"Model should have written an error message");
}

- (void)testBoneParentOutOfRange
{
    NSString *source = @"2\n\
    Test\n\
    -1\n\
    0 0 0\n\
    Test2\n\
    16\n\
    0 0 0\n\
    0";
    NSURL *baseURL = [NSURL fileURLWithPath:@"/tmp/generic_item.mesh"];
    
    GLLModel *model;
    NSError *error = nil;
    XCTAssertNoThrow(model = [[GLLModel alloc] initASCIIFromString:source baseURL:baseURL parent:nil error:&error], @"Loading should never throw");
    XCTAssertNil(model, @"This model should not have loaded");
    XCTAssertNotNil(error, @"Model should have written an error message");
}

- (void)testBoneParentCircle
{
    NSString *source = @"2\n\
    Test\n\
    1\n\
    0 0 0\n\
    Test2\n\
    0\n\
    0 0 0\n\
    0";
    NSURL *baseURL = [NSURL fileURLWithPath:@"/tmp/generic_item.mesh"];
    
    GLLModel *model;
    NSError *error = nil;
    XCTAssertNoThrow(model = [[GLLModel alloc] initASCIIFromString:source baseURL:baseURL parent:nil error:&error], @"Loading should never throw");
    XCTAssertNil(model, @"This model should not have loaded");
    XCTAssertNotNil(error, @"Model should have written an error message");
}

- (void)testBoneIndexOutOfRange
{
    NSString *source = @"2 # bones\n\
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
    12 0 0 0\n\
    0.5 0 0\n\
    0 0 1\n\
    0 255 0  255\n\
    1 0\n\
    23 24 25 26\n\
    1 0 0 0\n\
    0.0 1.000000 0\n\
    0 0 1\n\
    0 0 255 255\n\
    0 1\n\
    120 240 480 960\n\
    0.5 0.5 0 0\n\
    1 # count of tris\n\
    0 1 2	";
    NSURL *baseURL = [NSURL fileURLWithPath:@"/tmp/generic_item.mesh"];
    
    GLLModel *model;
    NSError *error = nil;
    XCTAssertNoThrow(model = [[GLLModel alloc] initASCIIFromString:source baseURL:baseURL parent:nil error:&error], @"Loading should never throw");
    XCTAssertNil(model, @"This model should not have loaded");
    XCTAssertNotNil(error, @"Model should have written an error message");
}

- (void)testVertexElementOutOfRange
{
    NSString *source = @"2 # bones\n\
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
    10 11 12	";
    NSURL *baseURL = [NSURL fileURLWithPath:@"/tmp/generic_item.mesh"];
    
    GLLModel *model;
    NSError *error = nil;
    XCTAssertNoThrow(model = [[GLLModel alloc] initASCIIFromString:source baseURL:baseURL parent:nil error:&error], @"Loading should never throw");
    XCTAssertNil(model, @"This model should not have loaded");
    XCTAssertNotNil(error, @"Model should have written an error message");
}

- (void)testArbitraryString
{
    NSString *source = @"2 # bones\n\
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
    I've been working on the railroad...\n\
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
    10 11 12	";
    NSURL *baseURL = [NSURL fileURLWithPath:@"/tmp/generic_item.mesh"];
    
    GLLModel *model;
    NSError *error = nil;
    XCTAssertNoThrow(model = [[GLLModel alloc] initASCIIFromString:source baseURL:baseURL parent:nil error:&error], @"Loading should never throw");
    XCTAssertNil(model, @"This model should not have loaded");
    XCTAssertNotNil(error, @"Model should have written an error message");
}

- (void)testBinaryAsASCII
{
    uint8_t bytes[] = { 0x00, 0x00, 0x00, 0x00, // Bone count
        
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
        0x00, 0x00, 0x00, 0x00, // tangent
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
        0x01, 0x00, 0x00, 0x00, // Count of triangles
        0x00, 0x00, 0x00, 0x00, // index 1
        0x01, 0x00, 0x00, 0x00, // index 2
        0x02, 0x00, 0x00, 0x00, // index 3
    };
    
    NSString *source = [[NSString alloc] initWithBytes:bytes length:sizeof(bytes) encoding:NSMacOSRomanStringEncoding];
    NSURL *baseURL = [NSURL fileURLWithPath:@"/tmp/generic_item.mesh"];
    
    GLLModel *model;
    NSError *error = nil;
    XCTAssertNoThrow(model = [[GLLModel alloc] initASCIIFromString:source baseURL:baseURL parent:nil error:&error], @"Loading should never throw");
    XCTAssertNil(model, @"This model should not have loaded");
    XCTAssertNotNil(error, @"Model should have written an error message");
}

@end
