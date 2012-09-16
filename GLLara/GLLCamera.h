//
//  GLLCamera.h
//  GLLara
//
//  Created by Torsten Kammer on 09.09.12.
//  Copyright (c) 2012 Torsten Kammer. All rights reserved.
//

#import <Foundation/Foundation.h>
#import <CoreData/CoreData.h>

#import "simd_types.h"

@class GLLCameraTarget;

@interface GLLCamera : NSManagedObject

@property (nonatomic) BOOL cameraLocked;
@property (nonatomic) float distance;
@property (nonatomic) float farDistance;
@property (nonatomic) float fieldOfViewY;
@property (nonatomic) int64_t index;
@property (nonatomic) float latitude;
@property (nonatomic) float longitude;
@property (nonatomic) float nearDistance;
@property (nonatomic) float positionX;
@property (nonatomic) float positionY;
@property (nonatomic) float positionZ;
@property (nonatomic) float windowHeight;
@property (nonatomic) BOOL windowSizeLocked;
@property (nonatomic) float windowWidth;
@property (nonatomic, retain) GLLCameraTarget *target;

// Transient
@property (nonatomic) float actualWindowHeight;
@property (nonatomic) float actualWindowWidth;

// Completely independent
@property (nonatomic) float latestWindowHeight;
@property (nonatomic) float latestWindowWidth;

// Derived
@property (nonatomic) float currentPositionX;
@property (nonatomic) float currentPositionY;
@property (nonatomic) float currentPositionZ;

@property (nonatomic, readonly) mat_float16 viewProjectionMatrix;
@property (nonatomic, readonly) vec_float4 cameraWorldPosition;

// Used by the render to image functionality
- (mat_float16)viewProjectionMatrixForAspectRatio:(float)aspect;

@property (nonatomic, readonly) mat_float16 viewMatrix;

// Used for input
- (void)moveLocalX:(float)deltaX y:(float)deltaY z:(float)deltaZ;

@end
