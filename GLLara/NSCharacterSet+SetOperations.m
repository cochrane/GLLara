//
//  NSCharacterSet+SetOperations.m
//  GLLara
//
//  Created by Torsten Kammer on 24.02.13.
//  Copyright (c) 2013 Torsten Kammer. All rights reserved.
//

#import "NSCharacterSet+SetOperations.h"

#include <xmmintrin.h>
#include <emmintrin.h>

@implementation NSCharacterSet (SetOperations)

- (BOOL)hasIntersectionWithSet:(NSCharacterSet *)other;
{
	NSData *myData = self.bitmapRepresentation;
	NSData *theirData = other.bitmapRepresentation;
	
	NSAssert(myData.length == 8192 && theirData.length == 8192, @"bitmap representation of character set should always be 8192 bytes");
	
	const __m128 *mine = (const __m128 *) myData.bytes;
	const __m128 *theirs = (const __m128 *) theirData.bytes;
	__m128 result = _mm_setzero_ps();
	for (NSUInteger i = 0; i < 512; i += 4)
	{
		result = _mm_or_ps(result, _mm_and_ps(mine[i + 0], theirs[i + 0]));
		result = _mm_or_ps(result, _mm_and_ps(mine[i + 1], theirs[i + 1]));
		result = _mm_or_ps(result, _mm_and_ps(mine[i + 2], theirs[i + 2]));
		result = _mm_or_ps(result, _mm_and_ps(mine[i + 3], theirs[i + 3]));
	}
	
	return _mm_movemask_ps(_mm_cmpneq_ps(result, _mm_setzero_ps()));
}

@end
