//
//  GLLMeshSelectionTest.m
//  GLLara
//
//  Created by Torsten Kammer on 08.03.13.
//  Copyright (c) 2013 Torsten Kammer. All rights reserved.
//

#import "GLLMeshSelectionTest.h"

#import "GLLDocument.h"
#import "GLLItem.h"
#import "GLLItemMesh.h"
#import "GLLItemMeshTexture.h"
#import "GLLModel.h"
#import "GLLSelection.h"

#import "GLLTestObjectWriter.h"

#import <Cocoa/Cocoa.h>

static NSURL *testModelURL;
static NSURL *testDocumentURL;

@implementation GLLMeshSelectionTest

+ (void)initialize
{
	testModelURL = [[NSBundle bundleForClass:self] URLForResource:@"generic_item" withExtension:@"mesh.ascii"];
	
	NSURL *temporaryDirectoryURL = [NSURL fileURLWithPath:NSTemporaryDirectory() isDirectory:YES];
	testDocumentURL = [NSURL URLWithString:[[[NSBundle bundleForClass:self] bundleIdentifier] stringByAppendingFormat:@"-testdocument.gllsc"] relativeToURL:temporaryDirectoryURL];
}

- (void)tearDown
{
	for (NSDocument *doc in [[NSDocumentController sharedDocumentController] documents])
		[doc close];
	[[NSRunLoop currentRunLoop] runUntilDate:[NSDate dateWithTimeIntervalSinceNow:0.01]];
}

- (void)testSelectTwoMeshes
{
	@autoreleasepool {
		NSError *error = nil;
		GLLDocument *doc = [[NSDocumentController sharedDocumentController] openUntitledDocumentAndDisplay:YES error:&error];
		
		STAssertNotNil(doc, @"Should open empty document");
		STAssertNil(error, @"Should not have error (got %@)", error);
		
		error = nil;
		GLLItem *item = [doc addModelAtURL:testModelURL error:&error];
		STAssertNotNil(item, @"Should have added model");
		STAssertNil(error, @"Should not have error (got %@)", error);
		
		STAssertEqualObjects([item.meshes[0] shaderName], @"Diffuse", @"shader name should  be diffuse, not %@", [item.meshes[0] shaderName]);
		STAssertEqualObjects([item.meshes[1] shaderName], @"Diffuse", @"shader name should  be diffuse, not %@", [item.meshes[1] shaderName]);

		[[NSRunLoop currentRunLoop] runUntilDate:[NSDate dateWithTimeIntervalSinceNow:0.1]];
		
		[[doc.selection mutableArrayValueForKeyPath:@"selectedObjects"] removeAllObjects];
		[[doc.selection mutableArrayValueForKeyPath:@"selectedObjects"] addObjectsFromArray:item.meshes.array];
		[[NSRunLoop currentRunLoop] runUntilDate:[NSDate dateWithTimeIntervalSinceNow:0.1]];
		
		STAssertEqualObjects([item.meshes[0] shaderName], @"Diffuse", @"shader name should still be diffuse, not %@", [item.meshes[0] shaderName]);
		STAssertEqualObjects([item.meshes[1] shaderName], @"Diffuse", @"shader name should still be diffuse, not %@", [item.meshes[1] shaderName]);
		
		[doc close];
		[[NSRunLoop currentRunLoop] runUntilDate:[NSDate dateWithTimeIntervalSinceNow:0.01]];
	}
}

- (void)testSelectTwoMeshesWithDifferentShaders
{
	@autoreleasepool {
		NSError *error = nil;
		GLLDocument *doc = [[NSDocumentController sharedDocumentController] openUntitledDocumentAndDisplay:YES error:&error];
		
		STAssertNotNil(doc, @"Should open empty document");
		STAssertNil(error, @"Should not have error (got %@)", error);
		
		GLLTestObjectWriter *writer = [[GLLTestObjectWriter alloc] init];
		writer.numBones = 1;
		writer.numMeshes = 2;
		[writer setNumUVLayers:1 forMesh:0];
		[writer setRenderGroup:5 renderParameterValues:@[] forMesh:0];
		[writer addTextureFilename:@"defaultColor.png" uvLayer:0 toMesh:0];
		[writer setNumUVLayers:1 forMesh:1];
		[writer setRenderGroup:10 renderParameterValues:@[] forMesh:1];
		[writer addTextureFilename:@"defaultReflection.jpg" uvLayer:0 toMesh:1];
		
		error = nil;
		GLLModel *model = [[GLLModel alloc] initASCIIFromString:writer.testFileString baseURL:testModelURL parent:nil error:&error];
		STAssertNotNil(model, @"Should have created model");
		STAssertNil(error, @"Should not have error (got %@)", error);
		
		error = nil;
		GLLItem *item = [doc addModel:model];
		STAssertNotNil(item, @"Should have added model");
		STAssertNil(error, @"Should not have error (got %@)", error);
		
		STAssertEqualObjects([item.meshes[0] shaderName], @"Diffuse", @"shader name should  be diffuse, not %@", [item.meshes[0] shaderName]);
		STAssertEqualObjects([item.meshes[1] shaderName], @"Shadeless", @"shader name should  be shadeless, not %@", [item.meshes[1] shaderName]);
		
		[[NSRunLoop currentRunLoop] runUntilDate:[NSDate dateWithTimeIntervalSinceNow:0.1]];
		
		[[doc.selection mutableArrayValueForKeyPath:@"selectedObjects"] removeAllObjects];
		[[doc.selection mutableArrayValueForKeyPath:@"selectedObjects"] addObjectsFromArray:item.meshes.array];
		[[NSRunLoop currentRunLoop] runUntilDate:[NSDate dateWithTimeIntervalSinceNow:0.1]];
		
		STAssertEqualObjects([item.meshes[0] shaderName], @"Diffuse", @"shader name should still be diffuse, not %@", [item.meshes[0] shaderName]);
		STAssertEqualObjects([item.meshes[1] shaderName], @"Shadeless", @"shader name should still be shadeless, not %@", [item.meshes[1] shaderName]);
		
		STAssertEquals([[item.meshes[0] textures] count], 1UL, @"Should have one texture");
		STAssertEqualObjects([[[item.meshes[0] textureWithIdentifier:@"diffuseTexture"] textureURL] lastPathComponent], @"defaultColor.png", @"Should have one texture");
		
		STAssertEquals([[item.meshes[1] textures] count], 1UL, @"Should have one texture");
		STAssertEqualObjects([[[item.meshes[1] textureWithIdentifier:@"diffuseTexture"] textureURL] lastPathComponent], @"defaultReflection.jpg", @"Should have one texture");
		
		[doc close];
		[[NSRunLoop currentRunLoop] runUntilDate:[NSDate dateWithTimeIntervalSinceNow:0.01]];
	}
}

@end
