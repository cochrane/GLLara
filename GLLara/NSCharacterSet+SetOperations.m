//
//  NSCharacterSet+SetOperations.m
//  GLLara
//
//  Created by Torsten Kammer on 24.02.13.
//  Copyright (c) 2013 Torsten Kammer. All rights reserved.
//

#import "NSCharacterSet+SetOperations.h"

@implementation NSCharacterSet (SetOperations)

- (BOOL)hasIntersectionWithSet:(NSCharacterSet *)other;
{
    NSData *myData = self.bitmapRepresentation;
    NSData *theirData = other.bitmapRepresentation;
    
    NSAssert(myData.length == 8192 && theirData.length == 8192, @"bitmap representation of character set should always be 8192 bytes");
    
    const uint64_t *mine = (const uint64_t *) myData.bytes;
    const uint64_t *theirs = (const uint64_t *) theirData.bytes;
    uint64_t result = 0;
    for (NSUInteger i = 0; i < (8192/(4*sizeof(mine[0]))) && result == 0; i += 4)
    {
        result |= mine[i+0] & theirs[i+0];
        result |= mine[i+1] & theirs[i+1];
        result |= mine[i+2] & theirs[i+2];
        result |= mine[i+3] & theirs[i+3];
    }
    
    return result != 0;
}

@end
