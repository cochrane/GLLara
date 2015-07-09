//
//  GLLRenderingTest.m
//  GLLara
//
//  Created by Torsten Kammer on 27.10.12.
//  Copyright (c) 2012 Torsten Kammer. All rights reserved.
//

#import "GLLRenderingTest.h"

#import <Accelerate/Accelerate.h>
#import <Cocoa/Cocoa.h>

#import "GLLCamera.h"
#import "GLLItemMesh.h"
#import "GLLColorRenderParameter.h"
#import "GLLDirectionalLight.h"
#import "GLLDocument.h"
#import "GLLItem.h"
#import "GLLItemBone.h"
#import "GLLModel.h"
#import "GLLTestObjectWriter.h"
#import "GLLRenderWindowController.h"
#import "GLLResourceManager.h"
#import "GLLView.h"
#import "LionSubscripting.h"
#import "NSArray+Map.h"

@implementation GLLRenderingTest

- (void)testAndGenerateExpected
{
	NSData *shadersListData = [NSData dataWithContentsOfURL:[[NSBundle mainBundle] URLForResource:@"xnaLaraDefault.modelparams" withExtension:@"plist"]];
	NSDictionary *shadersList = [NSPropertyListSerialization propertyListWithData:shadersListData options:NSPropertyListImmutable format:NULL error:NULL];
	
	NSURL *targetURL = [[NSURL fileURLWithPath:NSTemporaryDirectory()] URLByAppendingPathComponent:@"GLLara-rendered" isDirectory:YES];
	NSLog(@"Will find file at %@", targetURL);
	[[NSFileManager defaultManager] createDirectoryAtURL:targetURL withIntermediateDirectories:YES attributes:nil error:NULL];
	NSURL *testModelURL = [[NSBundle bundleForClass:[self class]] URLForResource:@"generic_item" withExtension:@"mesh.ascii"];
	
	NSURL *expectedURL = [[[[NSFileManager defaultManager] URLForDirectory:NSApplicationSupportDirectory inDomain:NSUserDomainMask appropriateForURL:nil create:YES error:NULL] URLByAppendingPathComponent:[[NSBundle mainBundle] bundleIdentifier] isDirectory:YES] URLByAppendingPathComponent:@"test-expected" isDirectory:YES];
	[[NSFileManager defaultManager] createDirectoryAtURL:expectedURL withIntermediateDirectories:YES attributes:nil error:NULL];
	
	for (NSString *shaderName in shadersList[@"shaders"])
	{
		@autoreleasepool
		{
			NSLog(@"Processing %@", shaderName);
			GLLTestObjectWriter *writer = [[GLLTestObjectWriter alloc] init];
			writer.numBones = 2;
			writer.numMeshes = 1;
			[writer setNumUVLayers:2 forMesh:0]; // Some shaders need this
			
			NSDictionary *shader = shadersList[@"shaders"][shaderName];
			
			// Find mesh group
			NSUInteger groupID = NSNotFound;
			for (NSString *groupName in shader[@"solidMeshGroups"])
			{
				if ([groupName hasPrefix:@"MeshGroup"])
					groupID = [[groupName substringFromIndex:[@"MeshGroup" length]] integerValue];
			}
			if (groupID == NSNotFound) continue;
			
			// Prepare render parameters
			NSArray *renderParameters = [shader[@"parameters"] map:^(NSString *paramName){
				if ([shadersList[@"renderParameterDescriptions"][@"type"] isEqual:@"color"]) return (NSNumber *) nil;
				double min = [shadersList[@"renderParameterDescriptions"][paramName][@"min"] doubleValue];
				double max = [shadersList[@"renderParameterDescriptions"][paramName][@"max"] doubleValue];
				return @((max-min)*0.5);
			}];
			
			[writer setRenderGroup:groupID renderParameterValues:renderParameters forMesh:0];
			
			// Add textures
			for (NSString *texture in shader[@"textures"])
				[writer addTextureFilename:[NSString stringWithFormat:@"test%@.png", [texture capitalizedString]] uvLayer:0 toMesh:0];
			
			// Create a document
			NSError *error = nil;
			GLLDocument *doc = [[NSDocumentController sharedDocumentController] openUntitledDocumentAndDisplay:YES error:&error];
			XCTAssertNotNil(doc, @"No document");
			XCTAssertNil(error, @"Got error: %@", error);

			GLLModel *model = [[GLLModel alloc] initASCIIFromString:writer.testFileString baseURL:testModelURL parent:nil error:&error];
			XCTAssertNotNil(model, @"Should have created model");
			XCTAssertNil(error, @"Should not have error (got %@)", error);
			
			error = nil;
			GLLItem *item = [doc addModel:model];
			XCTAssertNotNil(item, @"Should have added model");
			XCTAssertNil(error, @"Should not have error (got %@)", error);
			
			[doc.managedObjectContext processPendingChanges];
			[item.bones[1] setRotationX:0.5];
			[item.bones[1] setRotationY:0.5];
			[item.bones[1] setRotationZ:0.5];
			
			// Set colors
			for (GLLRenderParameter *parameter in [item.meshes[0] renderParameters])
			{
				if ([parameter.entity.name isEqual:@"GLLColorRenderParameter"])
					[parameter setValue:[NSColor redColor] forKey:@"value"];
			}
			
			// Ensure it didn't get automatically removed as punishment for failing to load
			NSFetchRequest *itemsRequest = [NSFetchRequest fetchRequestWithEntityName:@"GLLItem"];
			NSArray *items = [doc.managedObjectContext executeFetchRequest:itemsRequest error:NULL];
			XCTAssertEqual(items.count, 1UL, @"Item no longer in document");
			
			// Render the file
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
			
			[[NSRunLoop currentRunLoop] runUntilDate:[NSDate dateWithTimeIntervalSinceNow:.1]];
			
			NSURL *generatedImageURL = [targetURL URLByAppendingPathComponent:[NSString stringWithFormat:@"test%@.png", shaderName] isDirectory:NO];
			[controller renderToFile:generatedImageURL type:(__bridge NSString *)kUTTypePNG width:400 height:400];
			
			[doc close];
			[[GLLResourceManager sharedResourceManager] clearInternalCaches];
			[[NSRunLoop currentRunLoop] runUntilDate:[NSDate dateWithTimeIntervalSinceNow:.1]];
			
			// Compare to expected (if exists)
			NSURL *existingImageURL = [expectedURL URLByAppendingPathComponent:[NSString stringWithFormat:@"test%@.png", shaderName] isDirectory:NO];
			if (![existingImageURL checkResourceIsReachableAndReturnError:NULL])
			{
				NSLog(@"Expected image for %@ not found. Using generated as new expected", shaderName);
				[[NSFileManager defaultManager] copyItemAtURL:generatedImageURL toURL:existingImageURL error:NULL];
				continue;
			}
			
			NSImage *generated = [[NSImage alloc] initByReferencingURL:generatedImageURL];
			XCTAssertNotNil(generated, @"couldn't load generated image");
			
			NSImage *expected = [[NSImage alloc] initByReferencingURL:existingImageURL];
			XCTAssertNotNil(expected, @"couldn't load expected image even though bundle claims it exists.");
			
			NSBitmapImageRep *generatedRep = generated.representations[0];
			NSBitmapImageRep *expectedRep = expected.representations[0];
			
			XCTAssertEqual(generatedRep.bitmapFormat, expectedRep.bitmapFormat, @"different formats");
			XCTAssertEqual(generatedRep.bitsPerPixel, expectedRep.bitsPerPixel, @"different formats");
			XCTAssertEqual(generatedRep.bytesPerRow, expectedRep.bytesPerRow, @"different formats");
			XCTAssertEqual(generatedRep.isPlanar, expectedRep.isPlanar, @"different formats");
			XCTAssertEqual(generatedRep.samplesPerPixel, expectedRep.samplesPerPixel, @"different formats");
			
			NSUInteger numElements = 400*400*4;
			float averageAbsoluteDifference = 0;
			float maximumAbsoluteDifference = 0;
			float *generatedFloat = malloc(sizeof(float) * numElements);
			float *expectedFloat = malloc(sizeof(float) * numElements);
			float *difference = malloc(sizeof(float) * numElements);
			vDSP_vfltu8(generatedRep.bitmapData, 1, generatedFloat, 1, numElements);
			vDSP_vfltu8(expectedRep.bitmapData, 1, expectedFloat, 1, numElements);
			vDSP_vsub(generatedFloat, 1, expectedFloat, 1, difference, 1, numElements);
			free(generatedFloat);
			free(expectedFloat);
			vDSP_maxmgv(difference, 1, &maximumAbsoluteDifference, numElements);
			vDSP_meamgv(difference, 1, &averageAbsoluteDifference, numElements);
			free(difference);
			
			NSLog(@"average absolute diff: %f maximum absolute diff: %f", averageAbsoluteDifference, maximumAbsoluteDifference);
			XCTAssertEqual(memcmp(generatedRep.bitmapData, expectedRep.bitmapData, 400*generatedRep.bytesPerRow), 0, @"Different data");
			XCTAssertTrue(averageAbsoluteDifference < 0.1f, @"Average absolute difference too high (%f)", averageAbsoluteDifference);
			XCTAssertTrue(maximumAbsoluteDifference < 20.0f, @"Maximum absolute difference too high (%f)", maximumAbsoluteDifference);
		}
	}
	
	[[NSUserDefaults standardUserDefaults] registerDefaults:@{ @"tests-keepGenerated": @(NO) }];
	if (![[NSUserDefaults standardUserDefaults] boolForKey:@"tests-keepGenerated"])
		[[NSFileManager defaultManager] removeItemAtURL:targetURL error:NULL];
}

- (void)testOBJ
{
	NSData *shadersListData = [NSData dataWithContentsOfURL:[[NSBundle mainBundle] URLForResource:@"objFileParameters.modelparams" withExtension:@"plist"]];
	NSDictionary *shadersList = [NSPropertyListSerialization propertyListWithData:shadersListData options:NSPropertyListImmutable format:NULL error:NULL];
	
	NSURL *targetURL = [[NSURL fileURLWithPath:NSTemporaryDirectory()] URLByAppendingPathComponent:@"GLLara-rendered" isDirectory:YES];
	NSLog(@"Will find file at %@", targetURL);
	[[NSFileManager defaultManager] createDirectoryAtURL:targetURL withIntermediateDirectories:YES attributes:nil error:NULL];
	
	NSURL *expectedURL = [[[[NSFileManager defaultManager] URLForDirectory:NSApplicationSupportDirectory inDomain:NSUserDomainMask appropriateForURL:nil create:YES error:NULL] URLByAppendingPathComponent:[[NSBundle mainBundle] bundleIdentifier] isDirectory:YES] URLByAppendingPathComponent:@"test-expected" isDirectory:YES];
	[[NSFileManager defaultManager] createDirectoryAtURL:expectedURL withIntermediateDirectories:YES attributes:nil error:NULL];
	
	for (NSString *shaderName in shadersList[@"shaders"])
	{
		@autoreleasepool
		{
			NSLog(@"Processing %@", shaderName);
			
			NSString *objFileName = [NSString stringWithFormat:@"test%@.obj", shaderName];
			NSString *mtlFileName = [NSString stringWithFormat:@"test%@.mtl", shaderName];
			
			GLLTestObjectWriter *writer = [[GLLTestObjectWriter alloc] init];
			writer.numBones = 2;
			writer.numMeshes = 1;
			[writer setNumUVLayers:1 forMesh:0];
			writer.mtlLibName = mtlFileName;
			
			NSDictionary *shader = shadersList[@"shaders"][shaderName];
			
			// Add textures
			for (NSString *texture in shader[@"textures"])
			{
				NSString *objKey = @"";
				if ([texture isEqual:@"diffuseTexture"])
					objKey = @"map_Kd";
				else if ([texture isEqual:@"specularTexture"])
					objKey = @"map_Ks";
				else if ([texture isEqual:@"bumpTexture"])
					objKey = @"bump";

				[writer addTextureFilename:[[[NSBundle bundleForClass:[self class]] URLForResource:[NSString stringWithFormat:@"test%@", texture.capitalizedString] withExtension:@"png"] path] uvLayer:0 objIdentifier:objKey toMesh:0];
			}
			
			// Write to temporary files
			NSURL *objTemporaryURL = [NSURL URLWithString:objFileName relativeToURL:targetURL];
			NSURL *mtlTemporaryURL = [NSURL URLWithString:mtlFileName relativeToURL:targetURL];
			[writer.testFileStringOBJ writeToURL:objTemporaryURL atomically:NO encoding:NSUTF8StringEncoding error:NULL];
			[writer.testFileStringMTL writeToURL:mtlTemporaryURL atomically:NO encoding:NSUTF8StringEncoding error:NULL];
			
			// Create a document
			NSError *error = nil;
			GLLDocument *doc = [[NSDocumentController sharedDocumentController] openUntitledDocumentAndDisplay:YES error:&error];
			XCTAssertNotNil(doc, @"No document");
			XCTAssertNil(error, @"Got error: %@", error);
			
			error = nil;
			GLLItem *item = [doc addModelAtURL:objTemporaryURL error:&error];
			XCTAssertNotNil(item, @"Should have added model");
			XCTAssertNil(error, @"Should not have error (got %@)", error);
			
			XCTAssertEqualObjects(shaderName, [item.meshes[0] shaderName], @"Wrong shader chosen for mesh.");
			
			[doc.managedObjectContext processPendingChanges];
			
			// Ensure it didn't get automatically removed as punishment for failing to load
			NSFetchRequest *itemsRequest = [NSFetchRequest fetchRequestWithEntityName:@"GLLItem"];
			NSArray *items = [doc.managedObjectContext executeFetchRequest:itemsRequest error:NULL];
			XCTAssertEqual(items.count, 1UL, @"Item no longer in document");
			
			// Render the file
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
			
			[[NSRunLoop currentRunLoop] runUntilDate:[NSDate dateWithTimeIntervalSinceNow:.1]];
			
			NSURL *generatedImageURL = [targetURL URLByAppendingPathComponent:[NSString stringWithFormat:@"test%@.png", shaderName] isDirectory:NO];
			[controller renderToFile:generatedImageURL type:(__bridge NSString *)kUTTypePNG width:400 height:400];
			
			[doc close];
			[[GLLResourceManager sharedResourceManager] clearInternalCaches];
			[[NSRunLoop currentRunLoop] runUntilDate:[NSDate dateWithTimeIntervalSinceNow:.1]];
			
			// Compare to expected (if exists)
			NSURL *existingImageURL = [expectedURL URLByAppendingPathComponent:[NSString stringWithFormat:@"test%@.png", shaderName] isDirectory:NO];
			if (![existingImageURL checkResourceIsReachableAndReturnError:NULL])
			{
				NSLog(@"Expected image for %@ not found. Using generated as new expected", shaderName);
				[[NSFileManager defaultManager] copyItemAtURL:generatedImageURL toURL:existingImageURL error:NULL];
				continue;
			}
			
			NSImage *generated = [[NSImage alloc] initByReferencingURL:generatedImageURL];
			XCTAssertNotNil(generated, @"couldn't load generated image");
			
			NSImage *expected = [[NSImage alloc] initByReferencingURL:existingImageURL];
			XCTAssertNotNil(expected, @"couldn't load expected image even though bundle claims it exists.");
			
			NSBitmapImageRep *generatedRep = generated.representations[0];
			NSBitmapImageRep *expectedRep = expected.representations[0];
			
			XCTAssertEqual(generatedRep.bitmapFormat, expectedRep.bitmapFormat, @"different formats");
			XCTAssertEqual(generatedRep.bitsPerPixel, expectedRep.bitsPerPixel, @"different formats");
			XCTAssertEqual(generatedRep.bytesPerRow, expectedRep.bytesPerRow, @"different formats");
			XCTAssertEqual(generatedRep.isPlanar, expectedRep.isPlanar, @"different formats");
			XCTAssertEqual(generatedRep.samplesPerPixel, expectedRep.samplesPerPixel, @"different formats");
			
			NSUInteger numElements = 400*400*4;
			float averageAbsoluteDifference = 0;
			float maximumAbsoluteDifference = 0;
			float *generatedFloat = malloc(sizeof(float) * numElements);
			float *expectedFloat = malloc(sizeof(float) * numElements);
			float *difference = malloc(sizeof(float) * numElements);
			vDSP_vfltu8(generatedRep.bitmapData, 1, generatedFloat, 1, numElements);
			vDSP_vfltu8(expectedRep.bitmapData, 1, expectedFloat, 1, numElements);
			vDSP_vsub(generatedFloat, 1, expectedFloat, 1, difference, 1, numElements);
			free(generatedFloat);
			free(expectedFloat);
			vDSP_maxmgv(difference, 1, &maximumAbsoluteDifference, numElements);
			vDSP_meamgv(difference, 1, &averageAbsoluteDifference, numElements);
			free(difference);
			
			NSLog(@"average absolute diff: %f maximum absolute diff: %f", averageAbsoluteDifference, maximumAbsoluteDifference);
			XCTAssertEqual(memcmp(generatedRep.bitmapData, expectedRep.bitmapData, 400*generatedRep.bytesPerRow), 0, @"Different data");
			XCTAssertTrue(averageAbsoluteDifference < 0.1f, @"Average absolute difference too high (%f)", averageAbsoluteDifference);
			XCTAssertTrue(maximumAbsoluteDifference < 20.0f, @"Maximum absolute difference too high (%f)", maximumAbsoluteDifference);
		}
	}
	
//	[[NSUserDefaults standardUserDefaults] registerDefaults:@{ @"tests-keepGenerated": @(NO) }];
//	if (![[NSUserDefaults standardUserDefaults] boolForKey:@"tests-keepGenerated"])
//		[[NSFileManager defaultManager] removeItemAtURL:targetURL error:NULL];
}

@end
