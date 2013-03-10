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
			STAssertNotNil(doc, @"No document");
			STAssertNil(error, @"Got error: %@", error);

			GLLModel *model = [[GLLModel alloc] initASCIIFromString:writer.testFileString baseURL:testModelURL parent:nil error:&error];
			STAssertNotNil(model, @"Should have created model");
			STAssertNil(error, @"Should not have error (got %@)", error);
			
			error = nil;
			GLLItem *item = [doc addModel:model];
			STAssertNotNil(item, @"Should have added model");
			STAssertNil(error, @"Should not have error (got %@)", error);
			
			[doc.managedObjectContext processPendingChanges];
			[item.bones[1] setRotationX:0.5];
			[item.bones[1] setRotationY:0.5];
			[item.bones[1] setRotationZ:0.5];
			
			// Ensure it didn't get automatically removed as punishment for failing to load
			NSFetchRequest *itemsRequest = [NSFetchRequest fetchRequestWithEntityName:@"GLLItem"];
			NSArray *items = [doc.managedObjectContext executeFetchRequest:itemsRequest error:NULL];
			STAssertEquals(items.count, 1UL, @"Item no longer in document");
			
			// Render the file
			STAssertEquals(doc.windowControllers.count, 2UL, @"Should have two windows");
			GLLRenderWindowController *controller = doc.windowControllers[1];
			STAssertTrue([controller isKindOfClass:[GLLRenderWindowController class]], @"Should be a render window");
			controller.renderView.camera.latitude = -0.5;
			controller.renderView.camera.longitude = -0.89;
			controller.renderView.camera.distance = 2.0;
			
			NSFetchRequest *firstDiffuseFetchRequest = [NSFetchRequest fetchRequestWithEntityName:@"GLLDirectionalLight"];
			firstDiffuseFetchRequest.sortDescriptors = @[ [NSSortDescriptor sortDescriptorWithKey:@"index" ascending:YES] ];
			firstDiffuseFetchRequest.fetchLimit = 1;
			NSArray *lights = [doc.managedObjectContext executeFetchRequest:firstDiffuseFetchRequest error:NULL];
			STAssertEquals(lights.count, 1UL, @"Should have a light");
			GLLDirectionalLight *light = lights[0];
			STAssertTrue(light.isEnabled, @"Light should be turned on");
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
			STAssertNotNil(generated, @"couldn't load generated image");
			
			NSImage *expected = [[NSImage alloc] initByReferencingURL:existingImageURL];
			STAssertNotNil(expected, @"couldn't load expected image even though bundle claims it exists.");
			
			NSBitmapImageRep *generatedRep = generated.representations[0];
			NSBitmapImageRep *expectedRep = expected.representations[0];
			
			STAssertEquals(generatedRep.bitmapFormat, expectedRep.bitmapFormat, @"different formats");
			STAssertEquals(generatedRep.bitsPerPixel, expectedRep.bitsPerPixel, @"different formats");
			STAssertEquals(generatedRep.bytesPerRow, expectedRep.bytesPerRow, @"different formats");
			STAssertEquals(generatedRep.isPlanar, expectedRep.isPlanar, @"different formats");
			STAssertEquals(generatedRep.samplesPerPixel, expectedRep.samplesPerPixel, @"different formats");
			
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
			STAssertEquals(memcmp(generatedRep.bitmapData, expectedRep.bitmapData, 400*generatedRep.bytesPerRow), 0, @"Different data");
			STAssertTrue(averageAbsoluteDifference < 0.1f, @"Average absolute difference too high (%f)", averageAbsoluteDifference);
			STAssertTrue(maximumAbsoluteDifference < 20.0f, @"Maximum absolute difference too high (%f)", maximumAbsoluteDifference);
		}
	}
	
	[[NSUserDefaults standardUserDefaults] registerDefaults:@{ @"tests-keepGenerated": @(NO) }];
	if (![[NSUserDefaults standardUserDefaults] boolForKey:@"tests-keepGenerated"])
		[[NSFileManager defaultManager] removeItemAtURL:targetURL error:NULL];
}

@end
