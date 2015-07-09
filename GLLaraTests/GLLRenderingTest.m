//
//  GLLRenderingTest.m
//  GLLara
//
//  Created by Torsten Kammer on 27.10.12.
//  Copyright (c) 2012 Torsten Kammer. All rights reserved.
//

#import "GLLRenderingTest.h"

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
#import "NSArray+Map.h"

@implementation GLLRenderingTest

- (void)testGenerateExpected
{
	NSData *shadersListData = [NSData dataWithContentsOfURL:[[NSBundle mainBundle] URLForResource:@"xnaLaraDefault.modelparams" withExtension:@"plist"]];
	NSDictionary *shadersList = [NSPropertyListSerialization propertyListWithData:shadersListData options:NSPropertyListImmutable format:NULL error:NULL];
	
	NSURL *targetURL = [[NSURL fileURLWithPath:NSTemporaryDirectory()] URLByAppendingPathComponent:@"GLLara-expected" isDirectory:YES];
	NSLog(@"Will find file at %@", targetURL);
	[[NSFileManager defaultManager] createDirectoryAtURL:targetURL withIntermediateDirectories:YES attributes:nil error:NULL];
	NSURL *testModelURL = [[NSBundle bundleForClass:[self class]] URLForResource:@"generic_item" withExtension:@"mesh.ascii"];
	
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
			
			[controller renderToFile:[targetURL URLByAppendingPathComponent:[NSString stringWithFormat:@"test%@.png", shaderName] isDirectory:NO] type:(__bridge NSString *)kUTTypePNG width:400 height:400];
			
			[doc close];
			[[GLLResourceManager sharedResourceManager] clearInternalCaches];
			[[NSRunLoop currentRunLoop] runUntilDate:[NSDate dateWithTimeIntervalSinceNow:.1]];
			
			// Compare to expected (if exists)
		}
	}
}

@end
