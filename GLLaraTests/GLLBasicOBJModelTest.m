//
//  GLLBasicOBJModelTest.m
//  GLLara
//
//  Created by Torsten Kammer on 16.01.13.
//  Copyright (c) 2013 Torsten Kammer. All rights reserved.
//

#import "GLLBasicOBJModelTest.h"

#import "GLLModelMesh.h"
#import "GLLModelObj.h"

@interface GLLBasicOBJModelTest ()

@property (nonatomic) NSURL *tmpDirectoryURL;

- (void)writeString:(NSString *)string toTmpFile:(NSString *)filename;

@end

@implementation GLLBasicOBJModelTest

- (void)setUp
{
	NSString *tmp = NSTemporaryDirectory();
	
	NSURL *tmpDirectoryURL = [NSURL fileURLWithPath:tmp isDirectory:YES];
	self.tmpDirectoryURL = [[tmpDirectoryURL URLByAppendingPathComponent:[[NSBundle mainBundle] bundleIdentifier]] URLByAppendingPathComponent:@"Test"];
	NSError *error = nil;
	BOOL hasDirectory = [[NSFileManager defaultManager] createDirectoryAtURL:self.tmpDirectoryURL withIntermediateDirectories:YES attributes:nil error:&error];
	
	STAssertTrue(hasDirectory, @"Directory not available. Error: %@.", error);
}

- (void)tearDown
{
	[[NSFileManager defaultManager] removeItemAtURL:self.tmpDirectoryURL error:NULL];
}

- (void)testEmptyFile
{
	[self writeString:@"usemtl a" toTmpFile:@"test.obj"];
	[self writeString:@"newmtl a" toTmpFile:@"test.mtl"];
	
	NSError *error = nil;
	GLLModelObj *model = [[GLLModelObj alloc] initWithContentsOfURL:[self.tmpDirectoryURL URLByAppendingPathComponent:@"test.obj"] error:&error];
	STAssertNotNil(model, @"Did not load model");
	STAssertNil(error, @"Loading threw error: %@", error);
	
	STAssertEquals(model.bones.count, (NSUInteger) 1, @"OBJ should always have one bone.");
	STAssertEquals(model.meshes.count, (NSUInteger) 1, @"Model should have at least one mesh.");
}

- (void)testSimpleColoredFile
{
	NSString *obj = @"usemtl a\n\
v -.5 0 0\n\
vn 0 0 1\n\
vc 255 0 0 255\n\
vt 0 0\n\
v 0.5 0 0\n\
vn 0 0 1\n\
vc 0 255 0  255\n\
vt 1 0\n\
v 0.0 1.000000 0\n\
vn 0 0 1\n\
vc 0 0 255 255\n\
vt 0 1\n\
f 1/1/1/1 2/2/2/2 3/3/3/3";
	NSString *mtl = @"newmtl a";
	[self writeString:obj toTmpFile:@"testSimpleColoredFile.obj"];
	[self writeString:mtl toTmpFile:@"testSimpleColoredFile.mtl"];
	
	NSError *error = nil;
	GLLModelObj *model = [[GLLModelObj alloc] initWithContentsOfURL:[self.tmpDirectoryURL URLByAppendingPathComponent:@"testSimpleColoredFile.obj"] error:&error];
	STAssertNotNil(model, @"Did not load model");
	STAssertNil(error, @"Loading threw error: %@", error);
	
	STAssertEquals(model.bones.count, (NSUInteger) 1, @"OBJ should always have one bone.");
	STAssertEquals(model.meshes.count, (NSUInteger) 1, @"Model should have at least one mesh.");
	
	GLLModelMesh *mesh = model.meshes[0];
	STAssertEquals(mesh.countOfElements, (NSUInteger) 3, @"Not enough indices");
	STAssertEquals(mesh.countOfUVLayers, (NSUInteger) 1, @"Not enough UV layers");
	STAssertEquals(mesh.countOfVertices, (NSUInteger) 3, @"Not enough vertices");
	
	STAssertEquals(mesh.vertexData.length, (NSUInteger) 156, @"Vertex data count wrong");
	STAssertEquals(mesh.elementData.length, (NSUInteger) 12, @"Element data count wrong");
	STAssertEquals(mesh.stride, (NSUInteger) 52, @"Wrong stride");
	STAssertEquals(mesh.offsetForPosition, (NSUInteger) 0, @"Wrong offset");
	STAssertEquals(mesh.offsetForNormal, (NSUInteger) 12, @"Wrong offset");
	STAssertEquals(mesh.offsetForColor, (NSUInteger) 24, @"Wrong offset");
	STAssertEquals([mesh offsetForTexCoordLayer:0], (NSUInteger) 28, @"Wrong offset");
	STAssertEquals([mesh offsetForTangentLayer:0], (NSUInteger) 36, @"Wrong offset");
	
	const uint32_t *elements = mesh.elementData.bytes;
	STAssertTrue(memcmp(elements, (const uint32_t []) { 0, 1, 2 }, sizeof(uint32_t [3])) == 0, @"incorrect indices");
	
	const void *vertices = mesh.vertexData.bytes;
	STAssertTrue(memcmp(vertices + mesh.stride*0 + mesh.offsetForPosition,
						(float [3]) { -0.5, 0.0, 0.0 },
						sizeof(float [3])) == 0,
				 @"Vertex position 0");
	// Note that the loader reverses the winding order to match XNALara standards
	STAssertTrue(memcmp(vertices + mesh.stride*1 + mesh.offsetForPosition,
						(float [3]) { 0.0, 1.0, 0.0 },
						sizeof(float [3])) == 0,
				 @"Vertex position 1");
	STAssertTrue(memcmp(vertices + mesh.stride*2 + mesh.offsetForPosition,
						(float [3]) { 0.5, 0.0, 0.0 },
						sizeof(float [3])) == 0,
				 @"Vertex position 2");
}

#pragma mark - Helpers

- (void)writeString:(NSString *)string toTmpFile:(NSString *)filename;
{
	NSError *error = nil;
	NSURL *url = [self.tmpDirectoryURL URLByAppendingPathComponent:filename];
	BOOL result = [string writeToURL:url atomically:NO encoding:NSUTF8StringEncoding error:&error];
	STAssertTrue(result, @"Couldn't write test data");
	STAssertNil(error, @"Got error with test data: %@", error);
}

@end
