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
@property (nonatomic) double distance;
@property (nonatomic) double farDistance;
@property (nonatomic) double fieldOfViewY;
@property (nonatomic) int64_t index;
@property (nonatomic) double latitude;
@property (nonatomic) double longitude;
@property (nonatomic) double nearDistance;
@property (nonatomic) double positionX;
@property (nonatomic) double positionY;
@property (nonatomic) double positionZ;
@property (nonatomic) double windowHeight;
@property (nonatomic) BOOL windowSizeLocked;
@property (nonatomic) double windowWidth;
@property (nonatomic, retain) GLLCameraTarget *target;

// Transient
@property (nonatomic) double actualWindowHeight;
@property (nonatomic) double actualWindowWidth;

// Completely independent
@property (nonatomic) double latestWindowHeight;
@property (nonatomic) double latestWindowWidth;

// Derived
@property (nonatomic) double currentPositionX;
@property (nonatomic) double currentPositionY;
@property (nonatomic) double currentPositionZ;

@property (nonatomic, readonly) mat_float16 viewProjectionMatrix;
@property (nonatomic, readonly) vec_float4 cameraWorldPosition;

// Used by the render to image functionality
- (mat_float16)viewProjectionMatrixForAspectRatio:(float)aspect;

@end
