//
//  GLLModelParametersTest.m
//  GLLara
//
//  Created by Torsten Kammer on 20.01.13.
//  Copyright (c) 2013 Torsten Kammer. All rights reserved.
//

#import "GLLModelParametersTest.h"

#import "GLLModelParams.h"

@implementation GLLModelParametersTest

- (void)testAlbinoSpider
{
	NSError *error = nil;
	GLLModelParams *params = [GLLModelParams parametersForName:@"albino_spider" error:&error];
	
	XCTAssertNotNil(params, @"Should have loaded params.");
	XCTAssertNil(error, @"Should not have thrown an error.");
	
	XCTAssertEqualObjects(params.base, [GLLModelParams parametersForName:@"xnaLaraDefault" error:NULL], @"base should be xnaLaraDefault.");
	XCTAssertEqualObjects([[params meshGroupsForMesh:@"body"] objectAtIndex:0], @"MeshGroup2", @"All parts should be mesh group 2");
	XCTAssertEqualObjects([[params meshGroupsForMesh:@"legs1"] objectAtIndex:0], @"MeshGroup2", @"All parts should be mesh group 2");
	XCTAssertEqualObjects([[params meshGroupsForMesh:@"legs2"] objectAtIndex:0], @"MeshGroup2", @"All parts should be mesh group 2");
	XCTAssertEqualObjects([[params meshGroupsForMesh:@"eyes"] objectAtIndex:0], @"MeshGroup2", @"All parts should be mesh group 2");
	
	XCTAssertEqualObjects([params renderParametersForMesh:@"body"][@"bumpSpecularAmount"], @(0.3), @"wrong default parameter");
	XCTAssertEqualObjects([params renderParametersForMesh:@"eyes"][@"bumpSpecularAmount"], @(0.4), @"wrong specific parameter");
}

@end
