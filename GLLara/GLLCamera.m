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

@interface GLLCamera ()

// Clears the target and sets camera position to the targets last position
- (void)_clearTarget;

@end

/*
 * To avoid infinite recursion, the window position are a bit odd. There are three sets: normal (or specified), actual and latest. specified are the ones saved in Core Data. When they change, the window gets resized. actual is set as the result of window resizes. It triggers a redraw. latest is meant for the UI. It returns actual, but on setting, sets specified (actual will get updated through the resize).
 */
@implementation GLLCamera

+ (NSSet *)keyPathsForValuesAffectingViewProjectionMatrix
{
	return [NSSet setWithObjects:@"fieldOfViewY", @"actualWindowWidth", @"actualWindowHeight", @"nearDistance", @"farDistance", @"cameraWorldPosition", nil];
}
+ (NSSet *)keyPathsForValuesAffectingCameraWorldPosition
{
	return [NSSet setWithObjects:@"distance", @"latitude", @"longitude", @"positionX", @"positionY", @"positionZ", @"target.position", nil];
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
+ (NSSet *)keyPathsForValuesAffectingLatestWindowHeight
{
	return [NSSet setWithObject:@"actualWindowHeight"];
}
+ (NSSet *)keyPathsForValuesAffectingLatestWindowWidth
{
	return [NSSet setWithObject:@"actualWindowWidth"];
}

@synthesize actualWindowHeight;
@synthesize actualWindowWidth;
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

- (void)willSave
{
	[self setPrimitiveValue:[self valueForKey:@"actualWindowWidth"] forKey:@"windowWidth"];
	[self setPrimitiveValue:[self valueForKey:@"actualWindowHeight"] forKey:@"windowHeight"];
}

- (void)setLongitude:(double)longitude
{
	[self willChangeValueForKey:@"longitude"];
	
	double inRange = fmod(longitude, 2*M_PI);
	if (inRange < 0.0) inRange += 2*M_PI;
	
	[self setPrimitiveValue:@(inRange) forKey:@"longitude"];
	[self didChangeValueForKey:@"longitude"];
}

- (double)latestWindowWidth
{
	return self.actualWindowWidth;
}
- (void)setLatestWindowWidth:(double)latestWindowWidth
{
	self.windowWidth = latestWindowWidth;
}
- (double)latestWindowHeight
{
	return self.actualWindowHeight;
}
- (void)setLatestWindowHeight:(double)latestWindowHeight
{
	self.windowHeight = latestWindowHeight;
}

- (void)setCurrentPositionX:(double)currentPositionX
{
	[self _clearTarget];
	self.positionX = currentPositionX;
}
- (double)currentPositionX
{
	if (self.target) return simd_extract(self.target.position, 0);
	else return self.positionX;
}

- (void)setCurrentPositionY:(double)currentPositionY
{	
	[self _clearTarget];
	self.positionY = currentPositionY;
}
- (double)currentPositionY
{
	if (self.target) return simd_extract(self.target.position, 1);
	else return self.positionY;
}

- (void)setCurrentPositionZ:(double)currentPositionZ
{
	[self _clearTarget];
	self.positionZ = currentPositionZ;
}
- (double)currentPositionZ
{
	if (self.target) return simd_extract(self.target.position, 2);
	else return self.positionZ;
}

- (vec_float4)cameraWorldPosition
{
	vec_float4 targetPosition = self.target ? self.target.position : simd_make( self.positionX, self.positionY, self.positionZ, 1.0f );
	
	vec_float4 viewDirection = simd_mat_vecmul(simd_mat_euler(simd_make(self.latitude, self.longitude, 0.0, 0.0), simd_e_w), -simd_e_z);
	
	return targetPosition - viewDirection * simd_splatf(self.distance);
}

- (mat_float16)viewProjectionMtrixForAspectRatio:(float)aspect;
{
	mat_float16 projection = simd_frustumMatrix(self.fieldOfViewY, aspect, self.nearDistance, self.farDistance);
	
	vec_float4 targetPosition = self.target ? self.target.position : simd_make( self.positionX, self.positionY, self.positionZ, 1.0f );
	
	vec_float4 viewDirection = simd_mat_vecmul(simd_mat_euler(simd_make(self.latitude, self.longitude, 0.0, 0.0), simd_e_w), -simd_e_z);
	
	vec_float4 position = targetPosition - viewDirection * simd_splatf(self.distance);
	
	mat_float16 lookat = simd_mat_lookat(viewDirection, position);
	
	return simd_mat_mul(projection, lookat);
}

- (mat_float16)viewProjectionMatrix
{
	return [self viewProjectionMtrixForAspectRatio:self.actualWindowWidth / self.actualWindowHeight];
}

#pragma mark - Private methods

- (void)_clearTarget;
{
	if (!self.target) return;
	
	vec_float4 targetPosition = self.target.position;
	self.positionX = simd_extract(targetPosition, 0);
	self.positionY = simd_extract(targetPosition, 1);
	self.positionZ = simd_extract(targetPosition, 2);
	self.target = nil;
}

@end
