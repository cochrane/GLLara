//
//  GLLItem.h
//  GLLara
//
//  Created by Torsten Kammer on 01.09.12.
//  Copyright (c) 2012 Torsten Kammer. All rights reserved.
//

#import <CoreData/CoreData.h>
#import <Foundation/Foundation.h>

#import "GLLVersion.h"
#import "GLLSourceListItem.h"
#import "simd_types.h"

@class TRInDataStream;
@class TROutDataStream;
@class GLLBoneTransformation;
@class GLLMesh;
@class GLLMeshSettings;
@class GLLModel;
@class GLLScene;

@interface GLLItem : NSManagedObject <GLLSourceListItem>

// From Core Data
@property (nonatomic, retain) NSData * itemURLBookmark;
@property (nonatomic) float scaleX;
@property (nonatomic) float scaleY;
@property (nonatomic) float scaleZ;
@property (nonatomic) BOOL isVisible;
@property (nonatomic, retain) NSOrderedSet *boneTransformations;
@property (nonatomic, retain) NSOrderedSet *meshSettings;

// Derived
@property (nonatomic, retain) NSURL *itemURL;

@property (nonatomic, copy, readonly) NSString *itemName;
@property (nonatomic, copy, readonly) NSString *itemDirectory;
@property (nonatomic, copy, readonly) NSString *displayName;

@property (nonatomic, retain) GLLModel *model;

@property (nonatomic, retain, readonly) NSArray *rootBoneTransformations;

- (GLLMeshSettings *)settingsForMesh:(GLLMesh *)mesh;

- (void)getTransforms:(mat_float16 *)matrices maxCount:(NSUInteger)maxCount forMesh:(GLLMesh *)mesh;

@end

@interface GLLItem (CoreDataGeneratedAccessors)

- (void)insertObject:(GLLBoneTransformation *)value inBoneTransformationsAtIndex:(NSUInteger)idx;
- (void)removeObjectFromBoneTransformationsAtIndex:(NSUInteger)idx;
- (void)insertBoneTransformations:(NSArray *)value atIndexes:(NSIndexSet *)indexes;
- (void)removeBoneTransformationsAtIndexes:(NSIndexSet *)indexes;
- (void)replaceObjectInBoneTransformationsAtIndex:(NSUInteger)idx withObject:(GLLBoneTransformation *)value;
- (void)replaceBoneTransformationsAtIndexes:(NSIndexSet *)indexes withBoneTransformations:(NSArray *)values;
- (void)addBoneTransformationsObject:(GLLBoneTransformation *)value;
- (void)removeBoneTransformationsObject:(GLLBoneTransformation *)value;
- (void)addBoneTransformations:(NSOrderedSet *)values;
- (void)removeBoneTransformations:(NSOrderedSet *)values;
- (void)insertObject:(GLLMeshSettings *)value inMeshSettingsAtIndex:(NSUInteger)idx;
- (void)removeObjectFromMeshSettingsAtIndex:(NSUInteger)idx;
- (void)insertMeshSettings:(NSArray *)value atIndexes:(NSIndexSet *)indexes;
- (void)removeMeshSettingsAtIndexes:(NSIndexSet *)indexes;
- (void)replaceObjectInMeshSettingsAtIndex:(NSUInteger)idx withObject:(GLLMeshSettings *)value;
- (void)replaceMeshSettingsAtIndexes:(NSIndexSet *)indexes withMeshSettings:(NSArray *)values;
- (void)addMeshSettingsObject:(GLLMeshSettings *)value;
- (void)removeMeshSettingsObject:(GLLMeshSettings *)value;
- (void)addMeshSettings:(NSOrderedSet *)values;
- (void)removeMeshSettings:(NSOrderedSet *)values;

@end
