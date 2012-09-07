//
//  GLLLight.m
//  GLLara
//
//  Created by Torsten Kammer on 07.09.12.
//  Copyright (c) 2012 Torsten Kammer. All rights reserved.
//

#import "GLLLight.h"

#import <AppKit/NSColorSpace.h>

#import "simd_matrix.h"

@implementation GLLLight

+ (NSSet *)keyPathsForValuesAffectingDataAsUniformBlock
{
	return [NSSet setWithObjects:@"isEnabled", @"latitude", @"longitude", @"color", @"intensity", @"shadowDepth", nil];
}

@dynamic isEnabled;
@dynamic index;
@dynamic latitude;
@dynamic longitude;
@dynamic color;
@dynamic intensity;
@dynamic shadowDepth;

- (void)setLongitude:(float)longitude
{
	[self willChangeValueForKey:@"longitude"];
	
	float inRange = fmodf(longitude, 2*M_PI);
	if (inRange < 0.0) inRange += 2*M_PI;
	
	[self setPrimitiveValue:@(inRange) forKey:@"longitude"];
	[self didChangeValueForKey:@"longitude"];
}

- (NSData *)dataAsUniformBlock
{
	if (!self.isEnabled)
	{
		struct GLLLightUniformBlock block = { { 0, 0, 0, 0 }, { 0, 0, 0, 0 }, 0.0, 0.0 };
		return [NSData dataWithBytes:&block length:sizeof(block)];
	}
	
	vec_float4 position = simd_mat_vecmul(simd_mat_euler(simd_make(self.latitude, self.longitude, 0.0, 0.0), simd_e_w), -simd_e_z);
	
	CGFloat r, g, b, a;
	[[self.color colorUsingColorSpace:[NSColorSpace genericRGBColorSpace]] getRed:&r green:&g blue:&b alpha:&a];
	
	struct GLLLightUniformBlock block = { .color = simd_make(r, g, b, a), .direction = position, .intensity = self.intensity, .shadowDepth = self.shadowDepth };
	return [NSData dataWithBytes:&block length:sizeof(block)];
}

#pragma mark - Source list item

- (BOOL)isSourceListHeader
{
	return NO;
}
- (NSString *)sourceListDisplayName
{
	return [NSString stringWithFormat:NSLocalizedString(@"Light %lu", @"source list: Light name format"), self.index + 1];
}
- (BOOL)hasChildrenInSourceList
{
	return NO;
}
- (NSUInteger)numberOfChildrenInSourceList
{
	return 0;
}
- (id)childInSourceListAtIndex:(NSUInteger)index;
{
	return nil;
}

@end
