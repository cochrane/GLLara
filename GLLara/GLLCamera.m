//
//  GLLCamera.m
//  GLLara
//
//  Created by Torsten Kammer on 09.09.12.
//  Copyright (c) 2012 Torsten Kammer. All rights reserved.
//

#import "GLLCamera.h"
#import "GLLCameraTarget.h"

#import "simd_matrix.h"
#import "simd_project.h"

@implementation GLLCamera

+ (NSSet *)keyPathsForValuesAffectingViewProjectionMatrix
{
	return [NSSet setWithObjects:@"distance", @"fieldOfViewY", @"latitude", @"longitude", @"positionX", @"positionY", @"positionZ", @"target.position", @"windowWidth", @"windowHeight", @"nearDistance", @"farDistance", nil];
}
+ (NSSet *)keyPathsForValuesAffectingViewProjectionMatrixData
{
	return [NSSet setWithObject:@"viewProjectionMatrix"];
}
+ (NSSet *)keyPathsForValuesAffectingCurrentPositionX
{
	return [NSSet setWithObjects:@"target.position", @"positionX", nil];
}
+ (NSSet *)keyPathsForValuesAffectingCurrentPositionY
{
	return [NSSet setWithObjects:@"target.position", @"positionY", nil];
}
+ (NSSet *)keyPathsForValuesAffectingCurrentPositionZ
{
	return [NSSet setWithObjects:@"target.position", @"positionZ", nil];
}

@dynamic cameraLocked;
@dynamic distance;
@dynamic farDistance;
@dynamic fieldOfViewY;
@dynamic index;
@dynamic latitude;
@dynamic longitude;
@dynamic nearDistance;
@dynamic positionX;
@dynamic positionY;
@dynamic positionZ;
@dynamic windowHeight;
@dynamic windowSizeLocked;
@dynamic windowWidth;
@dynamic target;

- (void)setCurrentPositionX:(double)currentPositionX
{
	if (self.target) self.target = nil;
	self.positionX = currentPositionX;
}
- (double)currentPositionX
{
	if (self.target) return simd_extract(self.target.position, 0);
	else return self.positionX;
}

- (void)setCurrentPositionY:(double)currentPositionY
{
	if (self.target) self.target = nil;
	self.positionY = currentPositionY;
}
- (double)currentPositionY
{
	if (self.target) return simd_extract(self.target.position, 1);
	else return self.positionY;
}

- (void)setCurrentPositionZ:(double)currentPositionZ
{
	if (self.target) self.target = nil;
	self.positionZ = currentPositionZ;
}
- (double)currentPositionZ
{
	if (self.target) return simd_extract(self.target.position, 2);
	else return self.positionZ;
}

- (mat_float16)viewProjectionMatrix
{
	mat_float16 projection = simd_frustumMatrix(self.fieldOfViewY, self.windowWidth / self.windowHeight, self.nearDistance, self.farDistance);
	
	vec_float4 targetPosition = self.target ? self.target.position : simd_make( self.positionX, self.positionY, self.positionZ, 1.0f );
	
	vec_float4 viewDirection = simd_mat_vecmul(simd_mat_euler(simd_make(self.latitude, self.longitude, 0.0, 0.0), simd_e_w), -simd_e_z);

	vec_float4 position = targetPosition - viewDirection * simd_splatf(self.distance);
	
	mat_float16 lookat = simd_mat_lookat(viewDirection, position);
	
	return simd_mat_mul(projection, lookat);
}
- (NSData *)viewProjectionMatrixData
{
	mat_float16 viewProjection = self.viewProjectionMatrix;
	return [NSData dataWithBytes:&viewProjection length:sizeof(viewProjection)];
}

@end
