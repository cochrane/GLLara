//
//  NSArray+Map.m
//  Fanfiction Downloader
//
//  Created by Torsten Kammer on 06.01.13.
//  Copyright (c) 2013 Torsten Kammer. All rights reserved.
//

#import "NSArray+Map.h"

static id mapMutable(id<NSFastEnumeration> collection, NSUInteger count, id(^function)(id))
{
    NSMutableArray *result = [[NSMutableArray alloc] initWithCapacity:count];
    
    for (id object in collection)
    {
        id newObject = function(object);
        if (!newObject) continue;
        [result addObject:newObject];
    }
    
    return result;
}

static id map(id<NSFastEnumeration> collection, NSUInteger count, id(^function)(id))
{
    return [mapMutable(collection, count, function) copy];
}

@implementation NSArray (Map)

- (NSArray *)map:(id (^)(id))block;
{
    return map(self, self.count, block);
}
- (NSMutableArray *)mapMutable:(id (^)(id))block;
{
    return mapMutable(self, self.count, block);
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
    return map(self, self.count, block);
}

@end

@implementation NSSet (Map)

- (NSArray *)map:(id (^)(id))block;
{
    return map(self, self.count, block);
}

@end

@implementation NSIndexSet (Map)

- (NSArray *)map:(id (^)(NSUInteger))block;
{
    if (self.count == 0) return @[];
    
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
