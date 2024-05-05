//
//  NSArray+Map.h
//  Fanfiction Downloader
//
//  Created by Torsten Kammer on 06.01.13.
//  Copyright (c) 2013 Torsten Kammer. All rights reserved.
//

#import <Foundation/Foundation.h>

@interface NSArray<__covariant ObjectType> (Map)

- (NSArray *)map:(id (^)(ObjectType))block;
- (NSMutableArray *)mapMutable:(id (^)(ObjectType))block;
- (NSArray *)mapAndJoin:(NSArray *(^)(id))block;

@end

@interface NSOrderedSet<__covariant ObjectType> (Map)

- (NSArray *)map:(id (^)(ObjectType))block;

@end

@interface NSDictionary<__covariant KeyType, __covariant ValueType> (Map)

- (NSDictionary *)mapValues:(id (^)(KeyType))block;
- (NSDictionary *)mapValuesWithKey:(id (^)(KeyType key, ValueType value))block;

@end

@interface NSSet<__covariant ObjectType> (Map)

- (NSArray *)map:(id (^)(ObjectType))block;

@end

@interface NSIndexSet (Map)

- (NSArray *)map:(id (^)(NSUInteger))block;

@end
