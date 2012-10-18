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
	
	GLLModel *model;
	NSError *error = nil;
	STAssertNoThrow(model = [[GLLModel alloc] initASCIIFromString:source parameters:nil baseURL:nil error:&error], @"Loading should never throw");
	STAssertNil(model, @"This model should not have loaded");
	STAssertNotNil(error, @"Model should have written an error message");
}

- (void)testTooManyBonesFile
{
	NSString *source = @"12 0";
	
	GLLModel *model;
	NSError *error = nil;
	STAssertNoThrow(model = [[GLLModel alloc] initASCIIFromString:source parameters:nil baseURL:nil error:&error], @"Loading should never throw");
	STAssertNil(model, @"This model should not have loaded");
	STAssertNotNil(error, @"Model should have written an error message");
}

- (void)testTooManyMeshesFile
{
	NSString *source = @"0 12";
	
	GLLModel *model;
	NSError *error = nil;
	STAssertNoThrow(model = [[GLLModel alloc] initASCIIFromString:source parameters:nil baseURL:nil error:&error], @"Loading should never throw");
	STAssertNil(model, @"This model should not have loaded");
	STAssertNotNil(error, @"Model should have written an error message");
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
	
	GLLModel *model;
	NSError *error = nil;
	STAssertNoThrow(model = [[GLLModel alloc] initASCIIFromString:source parameters:nil baseURL:nil error:&error], @"Loading should never throw");
	STAssertNil(model, @"This model should not have loaded");
	STAssertNotNil(error, @"Model should have written an error message");
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
	
	GLLModel *model;
	NSError *error = nil;
	STAssertNoThrow(model = [[GLLModel alloc] initASCIIFromString:source parameters:nil baseURL:nil error:&error], @"Loading should never throw");
	STAssertNil(model, @"This model should not have loaded");
	STAssertNotNil(error, @"Model should have written an error message");
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
	NSURL *baseURL = [NSURL fileURLWithPath:@"/tmp/testfile.mesh"];
	
	GLLModel *model;
	NSError *error = nil;
	STAssertNoThrow(model = [[GLLModel alloc] initASCIIFromString:source parameters:nil baseURL:baseURL error:&error], @"Loading should never throw");
	STAssertNil(model, @"This model should not have loaded");
	STAssertNotNil(error, @"Model should have written an error message");
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
	NSURL *baseURL = [NSURL fileURLWithPath:@"/tmp/testfile.mesh"];
	
	GLLModel *model;
	NSError *error = nil;
	STAssertNoThrow(model = [[GLLModel alloc] initASCIIFromString:source parameters:nil baseURL:baseURL error:&error], @"Loading should never throw");
	STAssertNil(model, @"This model should not have loaded");
	STAssertNotNil(error, @"Model should have written an error message");
}

@end
