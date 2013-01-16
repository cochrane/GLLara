//
//  GLLBasicOBJModelTest.m
//  GLLara
//
//  Created by Torsten Kammer on 16.01.13.
//  Copyright (c) 2013 Torsten Kammer. All rights reserved.
//

#import "GLLBasicOBJModelTest.h"

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
