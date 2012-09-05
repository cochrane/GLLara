//
//  GLLBoneTransformation.h
//  GLLara
//
//  Created by Torsten Kammer on 01.09.12.
//  Copyright (c) 2012 Torsten Kammer. All rights reserved.
//

#import <Foundation/Foundation.h>

#import "GLLSourceListItem.h"
#import "GLLVersion.h"
#import "simd_types.h"

@class GLLBone;
@class GLLItem;
@class TRInDataStream;
@class TROutDataStream;

@interface GLLBoneTransformation : NSObject <GLLSourceListItem>

- (id)initFromDataStream:(TRInDataStream *)stream version:(GLLSceneVersion)version item:(GLLItem *)item bone:(GLLBone *)bone;
- (id)initWithItem:(GLLItem *)item bone:(GLLBone *)bone;

- (void)writeToStream:(TROutDataStream *)stream;

@property (nonatomic, retain, readonly) GLLBone *bone;
@property (nonatomic, weak, readonly) GLLItem *item;

@property (nonatomic, assign) float rotationX;
@property (nonatomic, assign) float rotationY;
@property (nonatomic, assign) float rotationZ;
@property (nonatomic, assign) float positionX;
@property (nonatomic, assign) float positionY;
@property (nonatomic, assign) float positionZ;

// Used only during loading
@property (nonatomic, assign) float globalPositionX;
@property (nonatomic, assign) float globalPositionY;
@property (nonatomic, assign) float globalPositionZ;
- (void)calculateLocalPositions;

@property (nonatomic, assign, readonly) BOOL hasParent;
@property (nonatomic, weak, readonly) GLLBoneTransformation *parent;
@property (nonatomic, retain, readonly) NSArray *children;

// Transformations
@property (nonatomic, assign, readonly) mat_float16 relativeTransform;
@property (nonatomic, assign, readonly) mat_float16 globalTransform;

@end
