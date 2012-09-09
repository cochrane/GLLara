//
//  GLLBoneTransformation.h
//  GLLara
//
//  Created by Torsten Kammer on 01.09.12.
//  Copyright (c) 2012 Torsten Kammer. All rights reserved.
//

#import <CoreData/CoreData.h>
#import <Foundation/Foundation.h>

#import "GLLSourceListItem.h"
#import "GLLVersion.h"
#import "simd_types.h"

@class GLLBone;
@class GLLItem;
@class TRInDataStream;
@class TROutDataStream;

@interface GLLBoneTransformation : NSManagedObject <GLLSourceListItem>

// From core data
@property (nonatomic) float positionX;
@property (nonatomic) float positionY;
@property (nonatomic) float positionZ;
@property (nonatomic) float rotationX;
@property (nonatomic) float rotationY;
@property (nonatomic) float rotationZ;
@property (nonatomic, retain) GLLItem *item;

// Derived
@property (nonatomic, readonly) NSUInteger boneIndex;
@property (nonatomic, retain, readonly) GLLBone *bone;

@property (nonatomic, assign, readonly) BOOL hasParent;
@property (nonatomic, weak, readonly) GLLBoneTransformation *parent;
@property (nonatomic, retain, readonly) NSArray *children;

// Transformations
@property (nonatomic, assign, readonly) mat_float16 relativeTransform;
@property (nonatomic, assign, readonly) mat_float16 globalTransform;

@property (nonatomic, assign, readonly) vec_float4 globalPosition;

@end
