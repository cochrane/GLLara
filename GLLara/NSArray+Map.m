//
//  NSArray+Map.m
//  Fanfiction Downloader
//
//  Created by Torsten Kammer on 06.01.13.
//  Copyright (c) 2013 Torsten Kammer. All rights reserved.
//

#import "NSArray+Map.h"

@implementation NSArray (Map)

- (NSArray *)map:(id (^)(id))block;
{
	return [[self mapMutable:block] copy];
}
- (NSMutableArray *)mapMutable:(id (^)(id))block;
{
	NSMutableArray *result = [[NSMutableArray alloc] initWithCapacity:self.count];
	
	for (id object in self)
	{
		id newObject = block(object);
		if (!newObject) continue;
		[result addObject:newObject];
	}
	
	return result;
}
- (NSArray *)mapAndJoin:(NSArray *(^)(id))block;
{
	NSMutableArray *result = [[NSMutableArray alloc] initWithCapacity:self.count];
	
	for (id object in self)
	{
		NSArray *newObjects = block(object);
		if (!newObjects) continue;
		[result addObjectsFromArray:newObjects];
	}
	
	return result;
}

@end

@implementation NSOrderedSet (Map)

- (NSArray *)map:(id (^)(id))block;
{
	NSMutableArray *result = [[NSMutableArray alloc] initWithCapacity:self.count];
	
	for (id object in self)
	{
		id newObject = block(object);
		if (!newObject) continue;
		[result addObject:newObject];
	}
	
	return [result copy];
}

@end

@implementation NSDictionary (Map)

- (NSDictionary *)mapValues:(id (^)(id))block;
{
	return [self mapValuesWithKey:^(id key, id value) { return block(value); }];
}
- (NSDictionary *)mapValuesWithKey:(id (^)(id key, id value))block;
{
	NSMutableDictionary *result = [[NSMutableDictionary alloc] initWithCapacity:self.count];
	
	for (id key in self)
	{
		id newObject = block(key, self[key]);
		if (!newObject) continue;
		result[key] = newObject;
	}
	return [result copy];
}

@end

@implementation NSSet (Map)

- (NSArray *)map:(id (^)(id))block;
{
	NSMutableArray *result = [[NSMutableArray alloc] initWithCapacity:self.count];
	
	for (id object in self)
	{
		id newObject = block(object);
		if (!newObject) continue;
		[result addObject:newObject];
	}
	
	return [result copy];
}

@end

@implementation NSIndexSet (Map)

- (NSArray *)map:(id (^)(NSUInteger))block;
{
	NSMutableArray *result = [[NSMutableArray alloc] initWithCapacity:self.count];
	
	for (NSUInteger index = self.firstIndex; index <= self.lastIndex; index = [self indexGreaterThanIndex:index])
	{
		id newObject = block(index);
		if (!newObject) continue;
		[result addObject:newObject];
	}
	
	return [result copy];
}

@end