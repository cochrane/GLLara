//
//  GLLExportOBJTest.m
//  GLLara
//
//  Created by Torsten Kammer on 15.03.13.
//  Copyright (c) 2013 Torsten Kammer. All rights reserved.
//

#import "GLLExportOBJTest.h"

#import <Accelerate/Accelerate.h>
#import <Cocoa/Cocoa.h>

#import "GLLCamera.h"
#import "GLLDocument.h"
#import "GLLDirectionalLight.h"
#import "GLLItem.h"
#import "GLLItem+Export.h"
#import "GLLItemBone.h"
#import "GLLModel.h"
#import "GLLRenderWindowController.h"
#import "GLLResourceManager.h"
#import "GLLView.h"
#import "NSArray+Map.h"

#import "GLLTestObjectWriter.h"

@interface GLLExportOBJTest ()

@property (nonatomic) NSURL *tempDirectoryURL;
@property (nonatomic) NSURL *tempFileURL;
@property (nonatomic) NSString *pathFromTempDirectoryToOwnResources;

- (void)compareImage:(CGImageRef)first toImage:(CGImageRef)second maxDifferenceLimit:(float)maxDifferenceLimit avgDifferenceLimit:(float)avgDifferenceLimit;
- (void)setStandardLightAndCameraInDocument:(GLLDocument *)document;
- (void)writeString:(NSString *)string toTmpFile:(NSString *)filename;

- (GLLDocument *)openDocumentWithWriter:(GLLTestObjectWriter *)writer asOBJ:(BOOL)asObj item:(GLLItem *__autoreleasing*)item;

@end

@implementation GLLExportOBJTest

- (void)setUp
{
	NSString *tmp = NSTemporaryDirectory();
	
	NSURL *tmpDirectoryURL = [NSURL fileURLWithPath:tmp isDirectory:YES];
	self.tempDirectoryURL = [[tmpDirectoryURL URLByAppendingPathComponent:[[NSBundle mainBundle] bundleIdentifier]] URLByAppendingPathComponent:@"Test"];
	NSError *error = nil;
	BOOL hasDirectory = [[NSFileManager defaultManager] createDirectoryAtURL:self.tempDirectoryURL withIntermediateDirectories:YES attributes:nil error:&error];
	
	XCTAssertTrue(hasDirectory, @"Directory not available. Error: %@.", error);
	
	self.tempFileURL = [self.tempDirectoryURL URLByAppendingPathComponent:@"testfile.obj"];
	
	NSArray *dots = [self.tempDirectoryURL.pathComponents map:^(NSString *c){
		return @"..";
	}];
	self.pathFromTempDirectoryToOwnResources = [[dots componentsJoinedByString:@"/"] stringByAppendingString:[[NSBundle bundleForClass:[self class]] resourcePath]];
}

- (void)tearDown
{
	[[NSFileManager defaultManager] removeItemAtURL:self.tempDirectoryURL error:NULL];
	[[GLLResourceManager sharedResourceManager] clearInternalCaches];
	[[NSRunLoop currentRunLoop] runUntilDate:[NSDate dateWithTimeIntervalSinceNow:.1]];
}

/*
 * TODO: Needs additional tests for:
 * - diffuse objects exported as generic_mesh (with texture) in static current, poseable default, static default
 * - export diffuse as generic_mesh not as directory, with dir already added.
 */

- (void)testOBJExportDiffuseOnly
{
	/*
	 * Strategy:
	 * - Create test object
	 * - Open a document
	 * - Add test object
	 * - Render to image
	 * - Export test object
	 * - Remove test object
	 * - Import tested object
	 * - Assert right parameters
	 * - Set parameters to produce same results
	 * - Render to image
	 * - Compare
	 * - Close test document
	 * Do this for every combination of test file type, file output type that
	 * makes sense, ideally in some sort of loop. Also assert that exporting as
	 * obj with poseable won't do.
	 */
	GLLTestObjectWriter *writer = [[GLLTestObjectWriter alloc] init];
	writer.numBones = 2;
	writer.numMeshes = 1;
	[writer setNumUVLayers:2 forMesh:0]; // Some shaders need this
	
	// Diffuse
	[writer setRenderGroup:5 renderParameterValues:@[] forMesh:0];
	
	// Add textures
	[writer addTextureFilename:@"testDiffusetexture.png" uvLayer:0 toMesh:0];
	
	// Create a document
	
	GLLItem *item = nil;
	GLLDocument *doc = [self openDocumentWithWriter:writer asOBJ:NO item:&item];
	[item.bones[1] setRotationX:0.5];
	[item.bones[1] setRotationY:0.5];
	[item.bones[1] setRotationZ:0.5];
	
	// Render the file
	GLLRenderWindowController *controller = doc.windowControllers[1];
	XCTAssertTrue([controller isKindOfClass:[GLLRenderWindowController class]], @"Should be a render window");
	CGImageRef originalImage = [controller createImageOfSize:CGSizeMake(400, 400)];
	
	// Export this as OBJ
	NSError *error = nil;
	NSArray *fileWrappers = [item exportAsType:GLLItemExportTypeOBJ targetLocation:self.tempFileURL packageWithTextures:NO poseType:GLLCurrentPoseStatic error:&error];
	XCTAssertNotNil(fileWrappers, @"Should have created file wrappers");
	XCTAssertNil(error, @"Should not have error'd out, got %@", error);
	for (NSFileWrapper *wrapper in fileWrappers)
	{
		NSURL *targetURL = [NSURL URLWithString:wrapper.filename relativeToURL:self.tempFileURL];
		error = nil;
		BOOL result = [wrapper writeToURL:targetURL options:0 originalContentsURL:NULL error:&error];
		XCTAssertTrue(result, @"Should have written.");
		XCTAssertNil(error, @"Should not have given an error, got %@.", error);
	}
		
	// Remove it
	[doc.managedObjectContext deleteObject:item];
	item = nil;
	[doc.managedObjectContext processPendingChanges];
	
	// Add it again
	error = nil;
	GLLItem *item2 = [doc addModelAtURL:self.tempFileURL error:&error];
	XCTAssertNotNil(item2, @"Should have loaded new item");
	XCTAssertNil(error, @"Should not have error'd out, got %@", error);
	
	// Render the new thing
	[doc.managedObjectContext processPendingChanges];
	[[NSRunLoop currentRunLoop] runUntilDate:[NSDate dateWithTimeIntervalSinceNow:.1]];
	CGImageRef secondImage = [controller createImageOfSize:CGSizeMake(400, 400)];
	
	// Compare to expected (if exists)
	[self compareImage:originalImage toImage:secondImage maxDifferenceLimit:20.0f avgDifferenceLimit:0.1f];
	
	// Cleanup
	[doc close];
	CFRelease(originalImage);
	CFRelease(secondImage);
}

- (void)testOBJExportDiffuseStatic
{	
	GLLTestObjectWriter *writer = [[GLLTestObjectWriter alloc] init];
	writer.numBones = 2;
	writer.numMeshes = 1;
	[writer setNumUVLayers:2 forMesh:0]; // Some shaders need this
	
	// Diffuse
	[writer setRenderGroup:5 renderParameterValues:@[] forMesh:0];
	
	// Add textures
	[writer addTextureFilename:@"testDiffusetexture.png" uvLayer:0 toMesh:0];
	
	// Create a document
	GLLItem *item = nil;
	GLLDocument *doc = [self openDocumentWithWriter:writer asOBJ:NO item:&item];
	
	// Render the file
	GLLRenderWindowController *controller = doc.windowControllers[1];
	XCTAssertTrue([controller isKindOfClass:[GLLRenderWindowController class]], @"Should be a render window");
	CGImageRef originalImage = [controller createImageOfSize:CGSizeMake(400, 400)];
	
	// Rotate the bones
	[item.bones[1] setRotationX:0.5];
	[item.bones[1] setRotationY:0.5];
	[item.bones[1] setRotationZ:0.5];
	
	// Export this as OBJ
	NSError *error = nil;
	NSArray *fileWrappers = [item exportAsType:GLLItemExportTypeOBJ targetLocation:self.tempFileURL packageWithTextures:NO poseType:GLLDefaultPoseStatic error:&error];
	XCTAssertNotNil(fileWrappers, @"Should have created file wrappers");
	XCTAssertNil(error, @"Should not have error'd out, got %@", error);
	for (NSFileWrapper *wrapper in fileWrappers)
	{
		NSURL *targetURL = [NSURL URLWithString:wrapper.filename relativeToURL:self.tempFileURL];
		error = nil;
		BOOL result = [wrapper writeToURL:targetURL options:0 originalContentsURL:NULL error:&error];
		XCTAssertTrue(result, @"Should have written.");
		XCTAssertNil(error, @"Should not have given an error, got %@.", error);
	}
	
	// Remove it
	[doc.managedObjectContext deleteObject:item];
	item = nil;
	[doc.managedObjectContext processPendingChanges];
	[[NSRunLoop currentRunLoop] runUntilDate:[NSDate dateWithTimeIntervalSinceNow:.1]];
	
	// Add it again
	error = nil;
	GLLItem *item2 = [doc addModelAtURL:self.tempFileURL error:&error];
	XCTAssertNotNil(item2, @"Should have loaded new item");
	XCTAssertNil(error, @"Should not have error'd out, got %@", error);
	
	// Render the new thing
	[doc.managedObjectContext processPendingChanges];
	[[NSRunLoop currentRunLoop] runUntilDate:[NSDate dateWithTimeIntervalSinceNow:.1]];
	CGImageRef secondImage = [controller createImageOfSize:CGSizeMake(400, 400)];
	
	// Compare to expected (if exists)
	[self compareImage:originalImage toImage:secondImage maxDifferenceLimit:20.0f avgDifferenceLimit:0.1f];
	
	// Cleanup
	[doc close];
	CFRelease(originalImage);
	CFRelease(secondImage);
}

- (void)testOBJExportDiffuseBump
{	
	GLLTestObjectWriter *writer = [[GLLTestObjectWriter alloc] init];
	writer.numBones = 2;
	writer.numMeshes = 1;
	[writer setNumUVLayers:2 forMesh:0]; // Some shaders need this
	
	// Diffuse + Bump
	[writer setRenderGroup:4 renderParameterValues:@[] forMesh:0];
	
	// Add textures
	[writer addTextureFilename:@"testDiffusetexture.png" uvLayer:0 toMesh:0];
	[writer addTextureFilename:@"testBumptexture.png" uvLayer:0 toMesh:0];
	
	// Create a document
	GLLItem *item = nil;
	GLLDocument *doc = [self openDocumentWithWriter:writer asOBJ:NO item:&item];
	
	// Render the file
	GLLRenderWindowController *controller = doc.windowControllers[1];
	XCTAssertTrue([controller isKindOfClass:[GLLRenderWindowController class]], @"Should be a render window");
	CGImageRef originalImage = [controller createImageOfSize:CGSizeMake(400, 400)];
	
	// Export this as OBJ
	NSError *error = nil;
	NSArray *fileWrappers = [item exportAsType:GLLItemExportTypeOBJ targetLocation:self.tempFileURL packageWithTextures:NO poseType:GLLCurrentPoseStatic error:&error];
	XCTAssertNotNil(fileWrappers, @"Should have created file wrappers");
	XCTAssertNil(error, @"Should not have error'd out, got %@", error);
	for (NSFileWrapper *wrapper in fileWrappers)
	{
		NSURL *targetURL = [NSURL URLWithString:wrapper.filename relativeToURL:self.tempFileURL];
		error = nil;
		BOOL result = [wrapper writeToURL:targetURL options:0 originalContentsURL:NULL error:&error];
		XCTAssertTrue(result, @"Should have written.");
		XCTAssertNil(error, @"Should not have given an error, got %@.", error);
	}
	
	// Remove it
	[doc.managedObjectContext deleteObject:item];
	item = nil;
	[doc.managedObjectContext processPendingChanges];
	
	// Add it again
	error = nil;
	GLLItem *item2 = [doc addModelAtURL:self.tempFileURL error:&error];
	XCTAssertNotNil(item2, @"Should have loaded new item");
	XCTAssertNil(error, @"Should not have error'd out, got %@", error);
	
	// Render the new thing
	[doc.managedObjectContext processPendingChanges];
	[[NSRunLoop currentRunLoop] runUntilDate:[NSDate dateWithTimeIntervalSinceNow:.1]];
	CGImageRef secondImage = [controller createImageOfSize:CGSizeMake(400, 400)];
	
	// Compare to expected (if exists)
	[self compareImage:originalImage toImage:secondImage maxDifferenceLimit:20.0f avgDifferenceLimit:0.1f];
	
	// Cleanup
	[doc close];
	CFRelease(originalImage);
	CFRelease(secondImage);
}

- (void)testOBJExportDiffuseBumpSpecular
{
	GLLTestObjectWriter *writer = [[GLLTestObjectWriter alloc] init];
	writer.numBones = 2;
	writer.numMeshes = 1;
	[writer setNumUVLayers:2 forMesh:0]; // Some shaders need this
	
	// Diffuse, Lightmap, Bump, Specular
	[writer setRenderGroup:24 renderParameterValues:@[] forMesh:0];
	
	// Add textures
	// use default for lightmap - we don't care about it at all.
	[writer addTextureFilename:@"testDiffusetexture.png" uvLayer:0 toMesh:0];
	[writer addTextureFilename:@"defaultWhite.png" uvLayer:0 toMesh:0];
	[writer addTextureFilename:@"testBumptexture.png" uvLayer:0 toMesh:0];
	[writer addTextureFilename:@"testSpeculartexture.png" uvLayer:0 toMesh:0];
	
	// Create a document
	GLLItem *item = nil;
	GLLDocument *doc = [self openDocumentWithWriter:writer asOBJ:NO item:&item];

	// Render the file
	GLLRenderWindowController *controller = doc.windowControllers[1];
	XCTAssertTrue([controller isKindOfClass:[GLLRenderWindowController class]], @"Should be a render window");
	CGImageRef originalImage = [controller createImageOfSize:CGSizeMake(400, 400)];
	
	// Export this as OBJ
	NSError *error = nil;
	NSArray *fileWrappers = [item exportAsType:GLLItemExportTypeOBJ targetLocation:self.tempFileURL packageWithTextures:NO poseType:GLLCurrentPoseStatic error:&error];
	XCTAssertNotNil(fileWrappers, @"Should have created file wrappers");
	XCTAssertNil(error, @"Should not have error'd out, got %@", error);
	for (NSFileWrapper *wrapper in fileWrappers)
	{
		NSURL *targetURL = [NSURL URLWithString:wrapper.filename relativeToURL:self.tempFileURL];
		error = nil;
		BOOL result = [wrapper writeToURL:targetURL options:0 originalContentsURL:NULL error:&error];
		XCTAssertTrue(result, @"Should have written.");
		XCTAssertNil(error, @"Should not have given an error, got %@.", error);
	}
	
	// Remove it
	[doc.managedObjectContext deleteObject:item];
	item = nil;
	[doc.managedObjectContext processPendingChanges];
	
	// Add it again
	error = nil;
	GLLItem *item2 = [doc addModelAtURL:self.tempFileURL error:&error];
	XCTAssertNotNil(item2, @"Should have loaded new item");
	XCTAssertNil(error, @"Should not have error'd out, got %@", error);
	
	
	// Render the new thing
	[doc.managedObjectContext processPendingChanges];
	[[NSRunLoop currentRunLoop] runUntilDate:[NSDate dateWithTimeIntervalSinceNow:.1]];
	CGImageRef secondImage = [controller createImageOfSize:CGSizeMake(400, 400)];
	
	// Compare to expected (if exists)
	[self compareImage:originalImage toImage:secondImage maxDifferenceLimit:20.0f avgDifferenceLimit:0.1f];
	
	// Cleanup
	[doc close];
	CFRelease(originalImage);
	CFRelease(secondImage);
}

- (void)testOBJExportDiffuseSpecular
{	
	GLLTestObjectWriter *writer = [[GLLTestObjectWriter alloc] init];
	writer.numBones = 2;
	writer.numMeshes = 1;
	[writer setNumUVLayers:2 forMesh:0]; // Some shaders need this
	
	// Diffuse, Lightmap, Bump, Specular
	[writer setRenderGroup:24 renderParameterValues:@[] forMesh:0];
	
	// Add textures
	// use default for lightmap - we don't care about it at all.	
	[writer addTextureFilename:[self.pathFromTempDirectoryToOwnResources stringByAppendingPathComponent:@"testDiffusetexture.png"] uvLayer:0 objIdentifier:@"map_Kd" toMesh:0];
	[writer addTextureFilename:[self.pathFromTempDirectoryToOwnResources stringByAppendingPathComponent:@"testSpeculartexture.png"] uvLayer:0  objIdentifier:@"map_Ks" toMesh:0];
	
	GLLItem *item = nil;
	GLLDocument *doc = [self openDocumentWithWriter:writer asOBJ:YES item:&item];
	
	// Render the file
	GLLRenderWindowController *controller = doc.windowControllers[1];
	XCTAssertTrue([controller isKindOfClass:[GLLRenderWindowController class]], @"Should be a render window");
	CGImageRef originalImage = [controller createImageOfSize:CGSizeMake(400, 400)];
	
	// Export this as OBJ
	NSError *error = nil;
	NSArray *fileWrappers = [item exportAsType:GLLItemExportTypeOBJ targetLocation:self.tempFileURL packageWithTextures:NO poseType:GLLCurrentPoseStatic error:&error];
	XCTAssertNotNil(fileWrappers, @"Should have created file wrappers");
	XCTAssertNil(error, @"Should not have error'd out, got %@", error);
	for (NSFileWrapper *wrapper in fileWrappers)
	{
		NSURL *targetURL = [NSURL URLWithString:wrapper.filename relativeToURL:self.tempFileURL];
		error = nil;
		BOOL result = [wrapper writeToURL:targetURL options:0 originalContentsURL:NULL error:&error];
		XCTAssertTrue(result, @"Should have written.");
		XCTAssertNil(error, @"Should not have given an error, got %@.", error);
	}
	
	// Remove it
	[doc.managedObjectContext deleteObject:item];
	item = nil;
	[doc.managedObjectContext processPendingChanges];
	
	// Add it again
	error = nil;
	GLLItem *item2 = [doc addModelAtURL:self.tempFileURL error:&error];
	XCTAssertNotNil(item2, @"Should have loaded new item");
	XCTAssertNil(error, @"Should not have error'd out, got %@", error);
	
	
	// Render the new thing
	[doc.managedObjectContext processPendingChanges];
	[[NSRunLoop currentRunLoop] runUntilDate:[NSDate dateWithTimeIntervalSinceNow:.1]];
	CGImageRef secondImage = [controller createImageOfSize:CGSizeMake(400, 400)];
	
	// Compare to expected (if exists)
	[self compareImage:originalImage toImage:secondImage maxDifferenceLimit:20.0f avgDifferenceLimit:0.1f];
	
	// Cleanup
	[doc close];
	CFRelease(originalImage);
	CFRelease(secondImage);
}

- (void)testOBJExportTextureless
{	
	GLLTestObjectWriter *writer = [[GLLTestObjectWriter alloc] init];
	writer.numBones = 2;
	writer.numMeshes = 1;
	[writer setNumUVLayers:2 forMesh:0]; // Some shaders need this
	
	// Create a document
	GLLItem *item = nil;
	GLLDocument *doc = [self openDocumentWithWriter:writer asOBJ:YES item:&item];
	
	// Render the file
	GLLRenderWindowController *controller = doc.windowControllers[1];
	XCTAssertTrue([controller isKindOfClass:[GLLRenderWindowController class]], @"Should be a render window");
	CGImageRef originalImage = [controller createImageOfSize:CGSizeMake(400, 400)];
	
	// Export this as OBJ
	NSError *error = nil;
	NSArray *fileWrappers = [item exportAsType:GLLItemExportTypeOBJ targetLocation:self.tempFileURL packageWithTextures:NO poseType:GLLCurrentPoseStatic error:&error];
	XCTAssertNotNil(fileWrappers, @"Should have created file wrappers");
	XCTAssertNil(error, @"Should not have error'd out, got %@", error);
	for (NSFileWrapper *wrapper in fileWrappers)
	{
		NSURL *targetURL = [NSURL URLWithString:wrapper.filename relativeToURL:self.tempFileURL];
		error = nil;
		BOOL result = [wrapper writeToURL:targetURL options:0 originalContentsURL:NULL error:&error];
		XCTAssertTrue(result, @"Should have written.");
		XCTAssertNil(error, @"Should not have given an error, got %@.", error);
	}
	
	// Remove it
	[doc.managedObjectContext deleteObject:item];
	item = nil;
	[doc.managedObjectContext processPendingChanges];
	
	// Add it again
	error = nil;
	GLLItem *item2 = [doc addModelAtURL:self.tempFileURL error:&error];
	XCTAssertNotNil(item2, @"Should have loaded new item");
	XCTAssertNil(error, @"Should not have error'd out, got %@", error);
	
	// Render the new thing
	[doc.managedObjectContext processPendingChanges];
	[[NSRunLoop currentRunLoop] runUntilDate:[NSDate dateWithTimeIntervalSinceNow:.1]];
	CGImageRef secondImage = [controller createImageOfSize:CGSizeMake(400, 400)];
	
	// Compare to expected (if exists)
	[self compareImage:originalImage toImage:secondImage maxDifferenceLimit:20.0f avgDifferenceLimit:0.1f];
	
	// Cleanup
	[doc close];
	CFRelease(originalImage);
	CFRelease(secondImage);
}

- (void)testOBJExportWithTextures
{	
	GLLTestObjectWriter *writer = [[GLLTestObjectWriter alloc] init];
	writer.numBones = 2;
	writer.numMeshes = 1;
	[writer setNumUVLayers:2 forMesh:0]; // Some shaders need this
	
	// Diffuse
	[writer setRenderGroup:5 renderParameterValues:@[] forMesh:0];
	
	// Add textures
	[writer addTextureFilename:@"testDiffusetexture.png" uvLayer:0 toMesh:0];
	
	// Create a document
	GLLItem *item = nil;
	GLLDocument *doc = [self openDocumentWithWriter:writer asOBJ:NO item:&item];
	
	// Render the file	
	GLLRenderWindowController *controller = doc.windowControllers[1];
	XCTAssertTrue([controller isKindOfClass:[GLLRenderWindowController class]], @"Should be a render window");
	CGImageRef originalImage = [controller createImageOfSize:CGSizeMake(400, 400)];
	
	// Export this as OBJ
	NSError *error = nil;
	NSArray *fileWrappers = [item exportAsType:GLLItemExportTypeOBJ targetLocation:self.tempFileURL packageWithTextures:YES poseType:GLLDefaultPoseStatic error:&error];
	XCTAssertNotNil(fileWrappers, @"Should have created file wrappers");
	XCTAssertEqual(fileWrappers.count, 1UL, @"Should be only one directory wrapper");
	XCTAssertNil(error, @"Should not have error'd out, got %@", error);
	for (NSFileWrapper *wrapper in fileWrappers)
	{
		NSURL *targetURL = [NSURL URLWithString:wrapper.filename relativeToURL:self.tempFileURL];
		error = nil;
		BOOL result = [wrapper writeToURL:targetURL options:0 originalContentsURL:NULL error:&error];
		XCTAssertTrue(result, @"Should have written.");
		XCTAssertNil(error, @"Should not have given an error, got %@.", error);
	}
	
	// Remove it
	[doc.managedObjectContext deleteObject:item];
	item = nil;
	[doc.managedObjectContext processPendingChanges];
	[[NSRunLoop currentRunLoop] runUntilDate:[NSDate dateWithTimeIntervalSinceNow:.1]];
	
	// Add it again
	error = nil;
	GLLItem *item2 = [doc addModelAtURL:[self.tempFileURL URLByAppendingPathComponent:@"testfile.obj"] error:&error];
	XCTAssertNotNil(item2, @"Should have loaded new item");
	XCTAssertNil(error, @"Should not have error'd out, got %@", error);
	
	
	// Render the new thing
	[doc.managedObjectContext processPendingChanges];
	[[NSRunLoop currentRunLoop] runUntilDate:[NSDate dateWithTimeIntervalSinceNow:.1]];
	CGImageRef secondImage = [controller createImageOfSize:CGSizeMake(400, 400)];
		
	// Compare to expected (if exists)
	[self compareImage:originalImage toImage:secondImage maxDifferenceLimit:20.0f avgDifferenceLimit:0.1f];
	
	// Cleanup
	[doc close];
	CFRelease(originalImage);
	CFRelease(secondImage);
}


- (void)testImpossibleOBJExportAsPoseable
{
	GLLTestObjectWriter *writer = [[GLLTestObjectWriter alloc] init];
	writer.numBones = 2;
	writer.numMeshes = 1;
	[writer setNumUVLayers:2 forMesh:0]; // Some shaders need this
	
	// Diffuse
	[writer setRenderGroup:5 renderParameterValues:@[] forMesh:0];
	
	// Add textures
	[writer addTextureFilename:@"testDiffusetexture.png" uvLayer:0 toMesh:0];
	
	// Create a document
	GLLItem *item = nil;
	GLLDocument *doc = [self openDocumentWithWriter:writer asOBJ:NO item:&item];
	
	// Export this as poseable OBJ (of course there's no such thing)
	NSError *error = nil;
	NSArray *fileWrappers = [item exportAsType:GLLItemExportTypeOBJ targetLocation:self.tempFileURL packageWithTextures:YES poseType:GLLDefaultPosePoseable error:&error];
	XCTAssertNil(fileWrappers, @"There shouldn't be any file wrappers here. Got %@", fileWrappers);
	XCTAssertNotNil(error, @"Should have received some sort of error");
	
	// Cleanup
	[doc close];
}

#pragma mark - .mesh Export

- (void)testMeshExportDiffusePoseableDefault
{	
	GLLTestObjectWriter *writer = [[GLLTestObjectWriter alloc] init];
	writer.numBones = 2;
	writer.numMeshes = 1;
	[writer setNumUVLayers:2 forMesh:0]; // Some shaders need this
	
	// Diffuse + Bump
	[writer setRenderGroup:5 renderParameterValues:@[] forMesh:0];
	
	// Add textures
	[writer addTextureFilename:@"testDiffusetexture.png" uvLayer:0 toMesh:0];
	
	// Create a document
	GLLItem *item = nil;
	GLLDocument *doc = [self openDocumentWithWriter:writer asOBJ:NO item:&item];
	
	// Rotate the bones
	[item.bones[1] setRotationX:0.5];
	[item.bones[1] setRotationY:0.5];
	[item.bones[1] setRotationZ:0.5];
	
	// Render the file
	GLLRenderWindowController *controller = doc.windowControllers[1];
	XCTAssertTrue([controller isKindOfClass:[GLLRenderWindowController class]], @"Should be a render window");
	CGImageRef originalImage = [controller createImageOfSize:CGSizeMake(400, 400)];
	
	// Export this as OBJ
	NSError *error = nil;
	NSArray *fileWrappers = [item exportAsType:GLLItemExportTypeXNALara targetLocation:self.tempFileURL packageWithTextures:YES poseType:GLLDefaultPosePoseable error:&error];
	XCTAssertNotNil(fileWrappers, @"Should have created file wrappers");
	XCTAssertNil(error, @"Should not have error'd out, got %@", error);
	for (NSFileWrapper *wrapper in fileWrappers)
	{
		NSURL *targetURL = [NSURL URLWithString:wrapper.filename relativeToURL:self.tempFileURL];
		error = nil;
		BOOL result = [wrapper writeToURL:targetURL options:0 originalContentsURL:NULL error:&error];
		XCTAssertTrue(result, @"Should have written.");
		XCTAssertNil(error, @"Should not have given an error, got %@.", error);
	}
	
	// Remove it
	[doc.managedObjectContext deleteObject:item];
	item = nil;
	[doc.managedObjectContext processPendingChanges];
	
	// Add it again
	error = nil;
	GLLItem *item2 = [doc addModelAtURL:[self.tempFileURL URLByAppendingPathComponent:@"generic_item.mesh"] error:&error];
	XCTAssertNotNil(item2, @"Should have loaded new item");
	XCTAssertNil(error, @"Should not have error'd out, got %@", error);
	
	// Rotate the bones
	[item2.bones[1] setRotationX:0.5];
	[item2.bones[1] setRotationY:0.5];
	[item2.bones[1] setRotationZ:0.5];
	
	
	// Render the new thing
	[doc.managedObjectContext processPendingChanges];
	[[NSRunLoop currentRunLoop] runUntilDate:[NSDate dateWithTimeIntervalSinceNow:.1]];
	CGImageRef secondImage = [controller createImageOfSize:CGSizeMake(400, 400)];
	
	// Compare to expected (if exists)
	[self compareImage:originalImage toImage:secondImage maxDifferenceLimit:20.0f avgDifferenceLimit:0.1f];
	
	// Cleanup
	[doc close];
	CFRelease(originalImage);
	CFRelease(secondImage);
}

- (void)testMeshExportDiffuseStaticDefault
{
	GLLTestObjectWriter *writer = [[GLLTestObjectWriter alloc] init];
	writer.numBones = 2;
	writer.numMeshes = 1;
	[writer setNumUVLayers:2 forMesh:0]; // Some shaders need this
	
	// Diffuse + Bump
	[writer setRenderGroup:5 renderParameterValues:@[] forMesh:0];
	
	// Add textures
	[writer addTextureFilename:@"testDiffusetexture.png" uvLayer:0 toMesh:0];
	
	// Create a document
	GLLItem *item = nil;
	GLLDocument *doc = [self openDocumentWithWriter:writer asOBJ:NO item:&item];
	
	// Render the file
	GLLRenderWindowController *controller = doc.windowControllers[1];
	XCTAssertTrue([controller isKindOfClass:[GLLRenderWindowController class]], @"Should be a render window");
	CGImageRef originalImage = [controller createImageOfSize:CGSizeMake(400, 400)];
	
	// Rotate the bones
	[item.bones[1] setRotationX:0.5];
	[item.bones[1] setRotationY:0.5];
	[item.bones[1] setRotationZ:0.5];
	
	// Export this as OBJ
	NSError *error = nil;
	NSArray *fileWrappers = [item exportAsType:GLLItemExportTypeXNALara targetLocation:self.tempFileURL packageWithTextures:YES poseType:GLLDefaultPoseStatic error:&error];
	XCTAssertNotNil(fileWrappers, @"Should have created file wrappers");
	XCTAssertNil(error, @"Should not have error'd out, got %@", error);
	for (NSFileWrapper *wrapper in fileWrappers)
	{
		NSURL *targetURL = [NSURL URLWithString:wrapper.filename relativeToURL:self.tempFileURL];
		error = nil;
		BOOL result = [wrapper writeToURL:targetURL options:0 originalContentsURL:NULL error:&error];
		XCTAssertTrue(result, @"Should have written.");
		XCTAssertNil(error, @"Should not have given an error, got %@.", error);
	}
	
	// Remove it
	[doc.managedObjectContext deleteObject:item];
	item = nil;
	[doc.managedObjectContext processPendingChanges];
	
	// Add it again
	error = nil;
	GLLItem *item2 = [doc addModelAtURL:[self.tempFileURL URLByAppendingPathComponent:@"generic_item.mesh"] error:&error];
	XCTAssertNotNil(item2, @"Should have loaded new item");
	XCTAssertNil(error, @"Should not have error'd out, got %@", error);
	
	// Check bone count
	XCTAssertEqual(item2.bones.count, 1UL, @"Not actually static!");
	
	// Render the new thing
	[doc.managedObjectContext processPendingChanges];
	[[NSRunLoop currentRunLoop] runUntilDate:[NSDate dateWithTimeIntervalSinceNow:.1]];
	CGImageRef secondImage = [controller createImageOfSize:CGSizeMake(400, 400)];
	
	// Compare to expected (if exists)
	[self compareImage:originalImage toImage:secondImage maxDifferenceLimit:20.0f avgDifferenceLimit:0.1f];
	
	// Cleanup
	[doc close];
	CFRelease(originalImage);
	CFRelease(secondImage);
}

- (void)testMeshExportDiffuseStaticCurrent
{
	GLLTestObjectWriter *writer = [[GLLTestObjectWriter alloc] init];
	writer.numBones = 2;
	writer.numMeshes = 1;
	[writer setNumUVLayers:2 forMesh:0]; // Some shaders need this
	
	// Diffuse + Bump
	[writer setRenderGroup:5 renderParameterValues:@[] forMesh:0];
	
	// Add textures
	[writer addTextureFilename:@"testDiffusetexture.png" uvLayer:0 toMesh:0];
	
	// Create a document
	GLLItem *item = nil;
	GLLDocument *doc = [self openDocumentWithWriter:writer asOBJ:NO item:&item];
	
	// Rotate the bones
	[item.bones[1] setRotationX:0.5];
	[item.bones[1] setRotationY:0.5];
	[item.bones[1] setRotationZ:0.5];
	
	// Render the file
	GLLRenderWindowController *controller = doc.windowControllers[1];
	XCTAssertTrue([controller isKindOfClass:[GLLRenderWindowController class]], @"Should be a render window");
	CGImageRef originalImage = [controller createImageOfSize:CGSizeMake(400, 400)];
	
	// Export this as OBJ
	NSError *error = nil;
	NSArray *fileWrappers = [item exportAsType:GLLItemExportTypeXNALara targetLocation:self.tempFileURL packageWithTextures:YES poseType:GLLCurrentPoseStatic error:&error];
	XCTAssertNotNil(fileWrappers, @"Should have created file wrappers");
	XCTAssertNil(error, @"Should not have error'd out, got %@", error);
	for (NSFileWrapper *wrapper in fileWrappers)
	{
		NSURL *targetURL = [NSURL URLWithString:wrapper.filename relativeToURL:self.tempFileURL];
		error = nil;
		BOOL result = [wrapper writeToURL:targetURL options:0 originalContentsURL:NULL error:&error];
		XCTAssertTrue(result, @"Should have written.");
		XCTAssertNil(error, @"Should not have given an error, got %@.", error);
	}
	
	// Remove it
	[doc.managedObjectContext deleteObject:item];
	item = nil;
	[doc.managedObjectContext processPendingChanges];
	
	// Add it again
	error = nil;
	GLLItem *item2 = [doc addModelAtURL:[self.tempFileURL URLByAppendingPathComponent:@"generic_item.mesh"] error:&error];
	XCTAssertNotNil(item2, @"Should have loaded new item");
	XCTAssertNil(error, @"Should not have error'd out, got %@", error);
	
	// Check bone count
	XCTAssertEqual(item2.bones.count, 1UL, @"Not actually static!");
	
	// Render the new thing
	[doc.managedObjectContext processPendingChanges];
	[[NSRunLoop currentRunLoop] runUntilDate:[NSDate dateWithTimeIntervalSinceNow:.1]];
	CGImageRef secondImage = [controller createImageOfSize:CGSizeMake(400, 400)];
	
	// Compare to expected (if exists)
	[self compareImage:originalImage toImage:secondImage maxDifferenceLimit:20.0f avgDifferenceLimit:0.1f];
	
	// Cleanup
	[doc close];
	CFRelease(originalImage);
	CFRelease(secondImage);
}

#pragma mark - Helpers

- (void)setStandardLightAndCameraInDocument:(GLLDocument *)doc;
{
	XCTAssertEqual(doc.windowControllers.count, 2UL, @"Should have two windows");
	GLLRenderWindowController *controller = doc.windowControllers[1];
	XCTAssertTrue([controller isKindOfClass:[GLLRenderWindowController class]], @"Should be a render window");
	controller.renderView.camera.latitude = -0.5;
	controller.renderView.camera.longitude = -0.89;
	controller.renderView.camera.distance = 2.0;
	
	NSFetchRequest *firstDiffuseFetchRequest = [NSFetchRequest fetchRequestWithEntityName:@"GLLDirectionalLight"];
	firstDiffuseFetchRequest.sortDescriptors = @[ [NSSortDescriptor sortDescriptorWithKey:@"index" ascending:YES] ];
	firstDiffuseFetchRequest.fetchLimit = 1;
	NSArray *lights = [doc.managedObjectContext executeFetchRequest:firstDiffuseFetchRequest error:NULL];
	XCTAssertEqual(lights.count, 1UL, @"Should have a light");
	GLLDirectionalLight *light = lights[0];
	XCTAssertTrue(light.isEnabled, @"Light should be turned on");
	light.latitude = -0.2;
	light.longitude = 0.5;
}

- (void)compareImage:(CGImageRef)first toImage:(CGImageRef)second maxDifferenceLimit:(float)maxDifferenceLimit avgDifferenceLimit:(float)avgDifferenceLimit;
{
	NSBitmapImageRep *firstRep = [[NSBitmapImageRep alloc] initWithCGImage:first];
	NSBitmapImageRep *secondRep = [[NSBitmapImageRep alloc] initWithCGImage:second];
	
	XCTAssertEqual(firstRep.bitmapFormat, secondRep.bitmapFormat, @"different formats");
	XCTAssertEqual(firstRep.bitsPerPixel, secondRep.bitsPerPixel, @"different formats");
	XCTAssertEqual(firstRep.bytesPerRow, secondRep.bytesPerRow, @"different formats");
	XCTAssertEqual(firstRep.isPlanar, secondRep.isPlanar, @"different formats");
	XCTAssertEqual(firstRep.samplesPerPixel, secondRep.samplesPerPixel, @"different formats");
	
	[[firstRep TIFFRepresentation] writeToURL:[self.tempDirectoryURL URLByAppendingPathComponent:@"first.tiff"] atomically:YES];
	[[secondRep TIFFRepresentation] writeToURL:[self.tempDirectoryURL URLByAppendingPathComponent:@"second.tiff"] atomically:YES];
	
	NSUInteger numElements = 400*400*4;
	float averageAbsoluteDifference = 0;
	float maximumAbsoluteDifference = 0;
	float *generatedFloat = malloc(sizeof(float) * numElements);
	float *expectedFloat = malloc(sizeof(float) * numElements);
	float *difference = malloc(sizeof(float) * numElements);
	vDSP_vfltu8(secondRep.bitmapData, 1, generatedFloat, 1, numElements);
	vDSP_vfltu8(firstRep.bitmapData, 1, expectedFloat, 1, numElements);
	vDSP_vsub(generatedFloat, 1, expectedFloat, 1, difference, 1, numElements);
	free(generatedFloat);
	free(expectedFloat);
	vDSP_maxmgv(difference, 1, &maximumAbsoluteDifference, numElements);
	vDSP_meamgv(difference, 1, &averageAbsoluteDifference, numElements);
	free(difference);
	
	XCTAssertTrue(averageAbsoluteDifference < avgDifferenceLimit, @"Average absolute difference too high (%f)", averageAbsoluteDifference);
	XCTAssertTrue(maximumAbsoluteDifference < maxDifferenceLimit, @"Maximum absolute difference too high (%f)", maximumAbsoluteDifference);
}

- (void)writeString:(NSString *)string toTmpFile:(NSString *)filename;
{
	NSError *error = nil;
	NSURL *url = [self.tempDirectoryURL URLByAppendingPathComponent:filename];
	BOOL result = [string writeToURL:url atomically:NO encoding:NSUTF8StringEncoding error:&error];
	XCTAssertTrue(result, @"Couldn't write test data");
	XCTAssertNil(error, @"Got error with test data: %@", error);
}

- (GLLDocument *)openDocumentWithWriter:(GLLTestObjectWriter *)writer asOBJ:(BOOL)asObj item:(GLLItem *__autoreleasing*)item;
{
	NSError *error = nil;
	GLLDocument *doc = [[NSDocumentController sharedDocumentController] openUntitledDocumentAndDisplay:YES error:&error];
	XCTAssertNotNil(doc, @"No document");
	XCTAssertNil(error, @"Got error: %@", error);
	
	error = nil;
	if (!asObj)
	{
		NSURL *testModelURL = [[NSBundle bundleForClass:[self class]] URLForResource:@"generic_item" withExtension:@"mesh.ascii"];
		
		GLLModel *model = [[GLLModel alloc] initASCIIFromString:writer.testFileString baseURL:testModelURL parent:nil error:&error];
		XCTAssertNotNil(model, @"Should have created model");
		XCTAssertNil(error, @"Should not have error (got %@)", error);
		
		error = nil;
		*item = [doc addModel:model];
		XCTAssertNotNil(*item, @"Should have added model");
	}
	else
	{
		NSURL *testModelURL = [self.tempDirectoryURL URLByAppendingPathComponent:@"testmodel.obj"];
		
		writer.mtlLibName = @"testmodel.mtl";
		
		// Write out
		[self writeString:writer.testFileStringOBJ toTmpFile:@"testmodel.obj"];
		[self writeString:writer.testFileStringMTL toTmpFile:@"testmodel.mtl"];
		
		// Add
		error = nil;
		*item = [doc addModelAtURL:testModelURL error:&error];
		XCTAssertNotNil(*item, @"Should have added model");
		XCTAssertNil(error, @"Should not have error (got %@)", error);
	}
	
	[doc.managedObjectContext processPendingChanges];
	
	// Ensure it didn't get automatically removed as punishment for failing to load
	NSFetchRequest *itemsRequest = [NSFetchRequest fetchRequestWithEntityName:@"GLLItem"];
	NSArray *items = [doc.managedObjectContext executeFetchRequest:itemsRequest error:NULL];
	XCTAssertEqual(items.count, 1UL, @"Item no longer in document");
	
	// Render the file
	[self setStandardLightAndCameraInDocument:doc];
	
	[[NSRunLoop currentRunLoop] runUntilDate:[NSDate dateWithTimeIntervalSinceNow:.1]];
	
	return doc;
}

@end
