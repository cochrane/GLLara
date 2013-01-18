//
//  MapTests.m
//  GLLara
//
//  Created by Torsten Kammer on 19.01.13.
//  Copyright (c) 2013 Torsten Kammer. All rights reserved.
//

#import "MapTests.h"

#import "NSArray+Map.h"

@implementation MapTests

- (void)testEmptyIndexSet
{
	NSIndexSet *empty = [NSIndexSet indexSet];
	
	NSArray *result = [empty map:^(NSUInteger index){
		return @(index);
	}];
	
	STAssertNotNil(result, @"Should return empty (but non-nil) array");
	STAssertEquals(result.count, 0UL, @"Should have no elements");
}

@end
