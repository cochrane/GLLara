//
//  GLLItemBone.h
//  GLLara
//
//  Created by Torsten Kammer on 01.09.12.
//  Copyright (c) 2012 Torsten Kammer. All rights reserved.
//

#import <CoreData/CoreData.h>
#import <Foundation/Foundation.h>

#import "GLLSourceListItem.h"
#import "GLLVersion.h"

@class GLLItem;
@class GLLModelBone;
@class TRInDataStream;
@class TROutDataStream;

@interface GLLItemBone : NSManagedObject <GLLSourceListItem>

// From core data
@property (nonatomic) float positionX;
@property (nonatomic) float positionY;
@property (nonatomic) float positionZ;
@property (nonatomic) float rotationX;
@property (nonatomic) float rotationY;
@property (nonatomic) float rotationZ;
@property (nonatomic, retain) GLLItem *item;
@property (nonatomic) NSValue *relativeTransform;
@property (nonatomic) NSValue *globalTransform;
@property (nonatomic) NSValue *globalPosition;

// Derived
@property (nonatomic, readonly) NSUInteger boneIndex;
@property (nonatomic, retain, readonly) GLLModelBone *bone;

@property (nonatomic, weak, readonly) GLLItemBone *parent;
@property (nonatomic, retain, readonly) NSArray *children;

@end
