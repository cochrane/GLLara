//
//  GLLItemBone.h
//  GLLara
//
//  Created by Torsten Kammer on 01.09.12.
//  Copyright (c) 2012 Torsten Kammer. All rights reserved.
//

#import <CoreData/CoreData.h>
#import <Foundation/Foundation.h>

#import "simd_matrix.h"

@class GLLItem;
@class GLLModelBone;
@class TRInDataStream;
@class TROutDataStream;

/*!
 * @abstract Stores per-bone data in the document.
 * @discussion This entity stores actual transformations. A bone can have
 * several items it belongs to, in the case of child items, but only one item
 * is the original root item (this is item #0).
 */
@interface GLLItemBone : NSManagedObject

// From core data
@property (nonatomic) float positionX;
@property (nonatomic) float positionY;
@property (nonatomic) float positionZ;
@property (nonatomic) float rotationX;
@property (nonatomic) float rotationY;
@property (nonatomic) float rotationZ;

// The "official" item; always the first item
@property (nonatomic, readonly) GLLItem *item;

// Local
@property (nonatomic) mat_float16 relativeTransform;
@property (nonatomic) mat_float16 globalTransform;
@property (nonatomic) vec_float4 globalPosition;
@property (nonatomic, copy) NSData *globalTransformValue;

// Derived
@property (nonatomic, readonly) NSUInteger boneIndex;
@property (nonatomic, retain, readonly) GLLModelBone *bone;

@property (nonatomic, weak, readonly) GLLItemBone *parent;
@property (nonatomic, retain, readonly) NSArray<GLLItemBone *> *children;

@property (nonatomic, readonly) NSUInteger parentIndexInCombined;

// Whether this bone was changed from its default rotation or position
// by the user
@property (nonatomic, assign, readonly) BOOL hasNonDefaultTransform;

// Checks whether the parameter is the bone or one of its ancestors
- (BOOL)isChildOfBone:(GLLItemBone *)bone;
- (BOOL)isChildOfAny:(id)boneSet;

// Updates the bone data. Should only be called from the item or a parent bone (or itself)
- (void)updateGlobalTransform;

// Undoes all changes made by the user and sets all position and rotation values back to 0.
- (void)resetAllValues;
// As above, but also for all descendants.
- (void)resetAllValuesRecursively;

@end

@interface GLLItemBone (CoreDataGeneratedAccessors)

- (void)insertObject:(GLLItem *)value inItemsAtIndex:(NSUInteger)idx;
- (void)removeObjectFromItemsAtIndex:(NSUInteger)idx;
- (void)insertItems:(NSArray *)value atIndexes:(NSIndexSet *)indexes;
- (void)removeItemsAtIndexes:(NSIndexSet *)indexes;
- (void)replaceObjectInItemsAtIndex:(NSUInteger)idx withObject:(GLLItemBone *)value;
- (void)replaceItemsAtIndexes:(NSIndexSet *)indexes withBones:(NSArray *)values;
- (void)addItemsObject:(GLLItemBone *)value;
- (void)removeItemsObject:(GLLItemBone *)value;
- (void)addItems:(NSOrderedSet *)values;
- (void)removeItems:(NSOrderedSet *)values;

@end
