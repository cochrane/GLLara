//
//  NSArray+Map.h
//  Fanfiction Downloader
//
//  Created by Torsten Kammer on 06.01.13.
//  Copyright (c) 2013 Torsten Kammer. All rights reserved.
//

#import <Foundation/Foundation.h>

@interface NSArray (Map)

- (NSArray *)map:(id (^)(id))block;
- (NSMutableArray *)mapMutable:(id (^)(id))block;
- (NSArray *)mapAndJoin:(NSArray *(^)(id))block;

@end

@interface NSOrderedSet (Map)

- (NSArray *)map:(id (^)(id))block;

@end

@interface NSDictionary (Map)

- (NSDictionary *)mapValues:(id (^)(id))block;
- (NSDictionary *)mapValuesWithKey:(id (^)(id key, id value))block;

@end

@interface NSSet (Map)

- (NSArray *)map:(id (^)(id))block;

@end