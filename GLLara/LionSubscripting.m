//
//  LionSubscripting.m
//  GLLara
//
//  Created by Torsten Kammer on 18.09.12.
//  Copyright (c) 2012 Torsten Kammer. All rights reserved.
//

#import "LionSubscripting.h"

@implementation NSArray (LionSubscripting)

- (id)objectAtIndexedSubscript:(NSUInteger)index;
{
	return [self objectAtIndex:index];
}

@end

@implementation NSMutableArray (LionSubscripting)

- (void)setObject:(id)object atIndexedSubscript:(NSUInteger)index;
{
	[self insertObject:object atIndex:index];
}

@end

@implementation NSOrderedSet (LionSubscripting)

- (id)objectAtIndexedSubscript:(NSUInteger)index;
{
	return [self objectAtIndex:index];
}

@end

@implementation NSMutableOrderedSet (LionSubscripting)

- (void)setObject:(id)object atIndexedSubscript:(NSUInteger)index;
{
	[self insertObject:object atIndex:index];
}

@end

@implementation NSDictionary (LionSubscripting)

- (id)objectForKeyedSubscript:(id)key;
{
	return [self objectForKey:key];
}

@end

@implementation NSMutableDictionary (LionSubscripting)

- (void)setObject:(id)object forKeyedSubscript:(id)key
{
	[self setObject:object forKey:key];
}

@end
