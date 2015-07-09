//
//  GLLEXIFTest.m
//  GLLara
//
//  Created by Torsten Kammer on 11.03.13.
//  Copyright (c) 2013 Torsten Kammer. All rights reserved.
//

#import "GLLEXIFTest.h"

#import "GLLDocument.h"
#import "GLLRenderWindowController.h"

@interface GLLEXIFTest ()

@property (nonatomic) NSURL *imageURL;

@end

@implementation GLLEXIFTest

- (void)setUp
{
	NSURL *targetURL = [[NSURL fileURLWithPath:NSTemporaryDirectory()] URLByAppendingPathComponent:@"GLLara-rendered" isDirectory:YES];
	[[NSFileManager defaultManager] createDirectoryAtURL:targetURL withIntermediateDirectories:YES attributes:nil error:NULL];
	self.imageURL = [targetURL URLByAppendingPathComponent:@"exifTest.jpg" isDirectory:NO];

	NSError *error = nil;
	GLLDocument *doc = [[NSDocumentController sharedDocumentController] openUntitledDocumentAndDisplay:YES error:&error];
	XCTAssertNotNil(doc, @"No document");
	XCTAssertNil(error, @"Got error: %@", error);
	
	// Render the file
	XCTAssertEqual(doc.windowControllers.count, 2UL, @"Should have two windows");
	GLLRenderWindowController *controller = doc.windowControllers[1];
	XCTAssertTrue([controller isKindOfClass:[GLLRenderWindowController class]], @"Should be a render window");
	
	[[NSRunLoop currentRunLoop] runUntilDate:[NSDate dateWithTimeIntervalSinceNow:.1]];
	
	[controller renderToFile:self.imageURL type:(__bridge NSString *)kUTTypeJPEG width:400 height:400];
	
	[doc close];
}

- (void)tearDown
{
	[[NSFileManager defaultManager] removeItemAtURL:self.imageURL error:NULL];
	self.imageURL = nil;
}

- (void)testSoftwareField
{
	CGImageSourceRef source = CGImageSourceCreateWithURL((__bridge CFURLRef) self.imageURL, NULL);
	
	NSDictionary *properties = (__bridge_transfer NSDictionary *) CGImageSourceCopyPropertiesAtIndex(source, 0, NULL);
	XCTAssertNotNil(properties, @"Image should have associated properties");
	
	NSDictionary *tiffDict = properties[(__bridge NSString *) kCGImagePropertyTIFFDictionary];
	XCTAssertNotNil(tiffDict, @"Image should have TIFF dictionary");
	
	XCTAssertTrue([tiffDict[(__bridge NSString *)kCGImagePropertyTIFFSoftware] hasPrefix:@"GLLara"], @"Software field should exist and start with GLLara");
	
	CFRelease(source);
}

@end
