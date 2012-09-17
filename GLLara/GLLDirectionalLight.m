//
//  GLLLight.m
//  GLLara
//
//  Created by Torsten Kammer on 07.09.12.
//  Copyright (c) 2012 Torsten Kammer. All rights reserved.
//

#import "GLLDirectionalLight.h"

#import <AppKit/NSColorSpace.h>

#import "simd_matrix.h"

@implementation GLLDirectionalLight

+ (NSSet *)keyPathsForValuesAffectingUniformBlock
{
	return [NSSet setWithObjects:@"isEnabled", @"latitude", @"longitude", @"diffuseColor", @"specularColor", nil];
}

@dynamic isEnabled;
@dynamic index;
@dynamic latitude;
@dynamic longitude;
@dynamic diffuseColor;
@dynamic specularColor;

- (void)setLongitude:(float)longitude
{
	[self willChangeValueForKey:@"longitude"];
	
	float inRange = fmodf(longitude, 2*M_PI);
	if (inRange < 0.0) inRange += 2*M_PI;
	
	[self setPrimitiveValue:@(inRange) forKey:@"longitude"];
	[self didChangeValueForKey:@"longitude"];
}

- (struct GLLLightUniformBlock)uniformBlock
{
	if (!self.isEnabled)
	{
		struct GLLLightUniformBlock block;
		bzero(&block, sizeof(block));
		return block;
	}
		
	struct GLLLightUniformBlock block;
	block.direction = simd_mat_vecmul(simd_mat_euler(simd_make(self.latitude, self.longitude, 0.0, 0.0), simd_e_w), -simd_e_z);
	
	CGFloat r, g, b, a;
	[[self.diffuseColor colorUsingColorSpace:[NSColorSpace genericRGBColorSpace]] getRed:&r green:&g blue:&b alpha:&a];
	block.diffuseColor = simd_make(r, g, b, a);
	[[self.specularColor colorUsingColorSpace:[NSColorSpace genericRGBColorSpace]] getRed:&r green:&g blue:&b alpha:&a];
	block.specularColor = simd_make(r, g, b, a);
	
	return block;
}

#pragma mark - Source list item

- (BOOL)isSourceListHeader
{
	return NO;
}
- (NSString *)sourceListDisplayName
{
	return [NSString stringWithFormat:NSLocalizedString(@"Light %lu", @"source list: Light name format"), self.index];
}
- (BOOL)isLeafInSourceList
{
	return YES;
}
- (NSUInteger)countOfSourceListChildren
{
	return 0;
}
- (id)objectInSourceListChildrenAtIndex:(NSUInteger)index;
{
	return nil;
}

@end
