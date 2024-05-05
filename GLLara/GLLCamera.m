//
//  GLLCamera.m
//  GLLara
//
//  Created by Torsten Kammer on 09.09.12.
//  Copyright (c) 2012 Torsten Kammer. All rights reserved.
//

#import "GLLCamera.h"

#import "simd_matrix.h"
#import "simd_project.h"
#import "GLLara-Swift.h"

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

- (void)setLongitude:(float)longitude
{
    [self willChangeValueForKey:@"longitude"];
    
    float inRange = fmodf(longitude, 2*M_PI);
    if (inRange < 0.0f) inRange += 2*M_PI;
    
    [self setPrimitiveValue:@(inRange) forKey:@"longitude"];
    [self didChangeValueForKey:@"longitude"];
}

- (void)setLatitude:(float)latitude
{
    [self willChangeValueForKey:@"latitude"];
    
    float epsilon = 1e-3;
    float maxAngle = M_PI_2 - epsilon;
    
    if (latitude < -maxAngle) {
        latitude = -maxAngle;
    } else if (latitude > maxAngle) {
        latitude = maxAngle;
    }
    
    [self setPrimitiveValue:@(latitude) forKey:@"latitude"];
    [self didChangeValueForKey:@"latitude"];
}

- (float)latestWindowWidth
{
    return self.actualWindowWidth;
}
- (void)setLatestWindowWidth:(float)latestWindowWidth
{
    self.windowWidth = latestWindowWidth;
}
- (float)latestWindowHeight
{
    return self.actualWindowHeight;
}
- (void)setLatestWindowHeight:(float)latestWindowHeight
{
    self.windowHeight = latestWindowHeight;
}

- (void)setCurrentPositionX:(float)currentPositionX
{
    [self _clearTarget];
    self.positionX = currentPositionX;
}
- (float)currentPositionX
{
    if (self.target) return self.target.position.x;
    else return self.positionX;
}

- (void)setCurrentPositionY:(float)currentPositionY
{
    [self _clearTarget];
    self.positionY = currentPositionY;
}
- (float)currentPositionY
{
    if (self.target) return self.target.position.y;
    else return self.positionY;
}

- (void)setCurrentPositionZ:(float)currentPositionZ
{
    [self _clearTarget];
    self.positionZ = currentPositionZ;
}
- (float)currentPositionZ
{
    if (self.target) return self.target.position.z;
    else return self.positionZ;
}

#pragma mark - Local moving

- (void)moveLocalX:(float)deltaX y:(float)deltaY z:(float)deltaZ;
{
    mat_float16 cameraRotation = simd_mat_euler(simd_make_float4(self.latitude, self.longitude, 0.0f, 0.0f), simd_e_w);
    
    // TODO isn't that just a rotate?
    vec_float4 delta = cameraRotation.columns[0] * deltaX + cameraRotation.columns[1] * deltaY + cameraRotation.columns[2] * deltaZ;
    
    self.currentPositionX += delta.x;
    self.currentPositionY += delta.y;
    self.currentPositionZ += delta.z;
}

#pragma mark - Calculate matrices

- (mat_float16)viewMatrix
{
    vec_float4 targetPosition = self.target ? self.target.position : simd_make_float4( self.positionX, self.positionY, self.positionZ, 1.0f );
    
    vec_float4 viewDirection = simd_mul(simd_mat_euler(simd_make_float4(self.latitude, self.longitude, 0.0f, 0.0f), simd_e_w), -simd_e_z);
    
    vec_float4 position = targetPosition - viewDirection * self.distance;
    
    return simd_mat_lookat(viewDirection, position);
}

- (vec_float4)cameraWorldPosition
{
    vec_float4 targetPosition = self.target ? self.target.position : simd_make_float4( self.positionX, self.positionY, self.positionZ, 1.0f );
    
    vec_float4 viewDirection = simd_mul(simd_mat_euler(simd_make_float4(self.latitude, self.longitude, 0.0f, 0.0f), simd_e_w), -simd_e_z);
    
    return targetPosition - viewDirection * self.distance;
}

- (mat_float16)viewProjectionMatrixForAspectRatio:(float)aspect;
{
    mat_float16 projection = simd_frustumMatrix(self.fieldOfViewY, aspect, self.nearDistance, self.farDistance);
    
    return simd_mul(projection, self.viewMatrix);
}

- (mat_float16)viewProjectionMatrix
{
    return [self viewProjectionMatrixForAspectRatio:self.actualWindowWidth / self.actualWindowHeight];
}

#pragma mark - Private methods

- (void)_clearTarget;
{
    if (!self.target) return;
    
    vec_float4 targetPosition = self.target.position;
    self.positionX = targetPosition.x;
    self.positionY = targetPosition.y;
    self.positionZ = targetPosition.z;
    self.target = nil;
}

@end
