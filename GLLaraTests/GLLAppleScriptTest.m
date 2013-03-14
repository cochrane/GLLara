//
//  GLLAppleScriptTest.m
//  GLLara
//
//  Created by Torsten Kammer on 13.03.13.
//  Copyright (c) 2013 Torsten Kammer. All rights reserved.
//

#import "GLLAppleScriptTest.h"

#import <Cocoa/Cocoa.h>

#import "GLLCamera.h"
#import "GLLDocument.h"
#import "GLLItem.h"
#import "GLLItemBone.h"
#import "GLLItemMesh.h"
#import "GLLItemMeshTexture.h"
#import "GLLResourceManager.h"

@interface GLLAppleScriptTest ()

@property (nonatomic) GLLDocument *document;
@property (nonatomic) GLLItem *item;

@end

@implementation GLLAppleScriptTest

- (void)setUp
{
	NSError *error = nil;
	self.document = [[NSDocumentController sharedDocumentController] openUntitledDocumentAndDisplay:YES error:&error];
	STAssertNotNil(self.document, @"No document");
	STAssertNil(error, @"Got error: %@", error);

	error = nil;
	self.item = [self.document addModelAtURL:[[NSBundle bundleForClass:[self class]] URLForResource:@"generic_item" withExtension:@"mesh.ascii"] error:&error];
	STAssertNotNil(self.item, @"Should have added model");
	STAssertNil(error, @"Should not have error (got %@)", error);
	[[NSRunLoop currentRunLoop] runUntilDate:[NSDate dateWithTimeIntervalSinceNow:0.1]];
}

- (void)tearDown
{
	[self.document close];
	self.document = nil;
	self.item = nil;
	
	[[GLLResourceManager sharedResourceManager] clearInternalCaches];
}

- (void)testBoneValueSet
{
	NSString *testScript = @"tell application \"GLLara\"\n\
	set rotation x of first bone of first object of first document to 1\n\
	end tell";
	
	NSAppleScript *script = [[NSAppleScript alloc] initWithSource:testScript];
	NSDictionary *errorDescription = nil;
	NSAppleEventDescriptor *descriptor = [script executeAndReturnError:&errorDescription];
	STAssertNotNil(descriptor, @"Should have gotten result");
	STAssertNil(errorDescription, @"Should have no error, got %@", errorDescription);
	
	GLLItemBone *firstBone = self.item.bones[0];
	STAssertEqualsWithAccuracy(firstBone.rotationX, 1.0f, 1e-4f, @"Rotation not set to value in script, is %f", firstBone.rotationX);
}

- (void)testBoneValueRead
{
	GLLItemBone *firstBone = self.item.bones[0];
	firstBone.rotationX = 1.0;
	
	NSString *testScript = @"tell application \"GLLara\"\n\
	get rotation x of first bone of first object of first document\n\
	end tell";
	
	NSAppleScript *script = [[NSAppleScript alloc] initWithSource:testScript];
	NSDictionary *errorDescription = nil;
	NSAppleEventDescriptor *descriptor = [script executeAndReturnError:&errorDescription];
	STAssertNotNil(descriptor, @"Should have gotten result");
	STAssertNil(errorDescription, @"Should have no error, got %@", errorDescription);
	
	NSAppleEventDescriptor *doubleDescriptor = [descriptor coerceToDescriptorType:'doub'];
	STAssertNotNil(doubleDescriptor, @"should be able to coerce data to double");
	NSData *doubleData = doubleDescriptor.data;
	STAssertNotNil(doubleData, @"Data should exist");
	STAssertEquals(doubleData.length, 8UL, @"Size of double data should be 8 bytes.");
	double value = 0;
	[doubleData getBytes:&value length:sizeof(double)];
	STAssertEqualsWithAccuracy(value, 1.0, 1e-4, @"Should have value that was previously set");
}

- (void)testCameraChange
{
	NSFetchRequest *camerasRequest = [NSFetchRequest fetchRequestWithEntityName:@"GLLCamera"];
	NSArray *result = [self.document.managedObjectContext executeFetchRequest:camerasRequest error:NULL];
	STAssertEquals(result.count, 1UL, @"Should have exactly one camera");
	
	GLLCamera *cam = result[0];
	cam.longitude = 1.0;
	
	NSString *testScript = @"tell application \"GLLara\"\n\
	set myCurrentLongitude to (longitude of camera of first render window of first document)\n\
	set (longitude of camera of first render window of first document) to (myCurrentLongitude + 1.0)\n\
	end tell";
	
	NSAppleScript *script = [[NSAppleScript alloc] initWithSource:testScript];
	NSDictionary *errorDescription = nil;
	NSAppleEventDescriptor *descriptor = [script executeAndReturnError:&errorDescription];
	STAssertNotNil(descriptor, @"Should have gotten result");
	STAssertNil(errorDescription, @"Should have no error, got %@", errorDescription);

	STAssertEqualsWithAccuracy(cam.longitude, 2.0f, 1e-4f, @"Should have updated camera");
}

- (void)testAddModel
{
	NSString *testScriptPattern = @"tell application \"GLLara\"\n\
	set theFile to \"%@\" as POSIX file\n\
	add model theFile to first document\n\
	end tell";
	
	NSString *testTexturePath = [[NSBundle bundleForClass:[self class]] pathForResource:@"generic_item" ofType:@"mesh.ascii"];
	NSString *testScript = [NSString stringWithFormat:testScriptPattern, testTexturePath];
	
	NSAppleScript *script = [[NSAppleScript alloc] initWithSource:testScript];
	NSDictionary *errorDescription = nil;
	NSAppleEventDescriptor *descriptor = [script executeAndReturnError:&errorDescription];
	STAssertNotNil(descriptor, @"Should have gotten result");
	STAssertNil(errorDescription, @"Should have no error, got %@", errorDescription);
	
	NSFetchRequest *itemsRequest = [NSFetchRequest fetchRequestWithEntityName:@"GLLItem"];
	NSArray *items = [self.document.managedObjectContext executeFetchRequest:itemsRequest error:NULL];
	STAssertEquals(items.count, 2UL, @"Should have two items now.");
}

- (void)testTextureChange
{
	NSString *testScriptPattern = @"tell application \"GLLara\"\n\
	set theFile to \"%@\" as POSIX file\n\
	set contents of first texture of first mesh of first object of first document to theFile\n\
	end tell";
	
	NSString *testTexturePath = [[NSBundle bundleForClass:[self class]] pathForResource:@"testDiffusetexture" ofType:@"png"];
	NSString *testScript = [NSString stringWithFormat:testScriptPattern, testTexturePath];
	
	NSAppleScript *script = [[NSAppleScript alloc] initWithSource:testScript];
	NSDictionary *errorDescription = nil;
	NSAppleEventDescriptor *descriptor = [script executeAndReturnError:&errorDescription];
	STAssertNotNil(descriptor, @"Should have gotten result");
	STAssertNil(errorDescription, @"Should have no error, got %@", errorDescription);

	GLLItemMesh *mesh = self.item.meshes[0];
	STAssertEqualObjects([[[mesh textureWithIdentifier:@"diffuseTexture"] textureURL] lastPathComponent], @"testDiffusetexture.png", @"Does not have new texture");
}

@end
