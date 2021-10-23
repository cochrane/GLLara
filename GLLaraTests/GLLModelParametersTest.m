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
    XCTAssertEqualObjects([[params paramsForMesh:@"body"].meshGroups objectAtIndex:0], @"MeshGroup2", @"All parts should be mesh group 2");
    XCTAssertEqualObjects([[params paramsForMesh:@"legs1"].meshGroups objectAtIndex:0], @"MeshGroup2", @"All parts should be mesh group 2");
    XCTAssertEqualObjects([[params paramsForMesh:@"legs2"].meshGroups objectAtIndex:0], @"MeshGroup2", @"All parts should be mesh group 2");
    XCTAssertEqualObjects([[params paramsForMesh:@"eyes"].meshGroups objectAtIndex:0], @"MeshGroup2", @"All parts should be mesh group 2");
    
    XCTAssertEqualObjects([params paramsForMesh:@"body"].renderParameters[@"bumpSpecularAmount"], @(0.3), @"wrong default parameter");
    XCTAssertEqualObjects([params paramsForMesh:@"eyes"].renderParameters[@"bumpSpecularAmount"], @(0.4), @"wrong specific parameter");
}

- (void)testLara
{
    NSError *error = nil;
    GLLModelParams *params = [GLLModelParams parametersForName:@"lara" error:&error];
    
    XCTAssertNotNil(params, @"Should have loaded params.");
    XCTAssertNil(error, @"Should not have thrown an error.");
}

@end
