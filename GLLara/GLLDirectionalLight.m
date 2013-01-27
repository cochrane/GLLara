//
//  GLLLight.m
//  GLLara
//
//  Created by Torsten Kammer on 07.09.12.
//  Copyright (c) 2012 Torsten Kammer. All rights reserved.
//

#import "GLLDirectionalLight.h"

#import "NSColor+Color32Bit.h"
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
	
	[self.diffuseColor get128BitRGBAComponents:block.diffuseColor];
	[self.specularColor get128BitRGBAComponents:block.specularColor];
	
	return block;
}

@end
