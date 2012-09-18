//
//  LionSubscripting.h
//  GLLara
//
//  Created by Torsten Kammer on 18.09.12.
//  Copyright (c) 2012 Torsten Kammer. All rights reserved.
//

#import <Foundation/Foundation.h>

@interface NSArray (LionSubscripting)

- (id)objectAtIndexedSubscript:(NSUInteger)index;

@end

@interface NSMutableArray (LionSubscripting)

- (void)setObject:(id)object atIndexedSubscript:(NSUInteger)index;

@end

@interface NSOrderedSet (LionSubscripting)

- (id)objectAtIndexedSubscript:(NSUInteger)index;

@end

@interface NSMutableOrderedSet (LionSubscripting)

- (void)setObject:(id)object atIndexedSubscript:(NSUInteger)index;

@end

@interface NSDictionary (LionSubscripting)

- (id)objectForKeyedSubscript:(id)key;

@end

@interface NSMutableDictionary (LionSubscripting)

- (void)setObject:(id)object forKeyedSubscript:(id)key;

@end
