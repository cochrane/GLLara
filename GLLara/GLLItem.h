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
@class GLLItemBone;
@class GLLItemMesh;
@class GLLModel;
@class GLLModelMesh;
@class GLLScene;
@class GLLRenderParameterDescription;

@interface GLLItem : NSManagedObject <GLLSourceListItem>

// From Core Data
@property (nonatomic, retain) NSData * itemURLBookmark;
@property (nonatomic) float scaleX;
@property (nonatomic) float scaleY;
@property (nonatomic) float scaleZ;
@property (nonatomic) BOOL isVisible;
@property (nonatomic, retain) NSOrderedSet *boneTransformations;
@property (nonatomic, retain) NSOrderedSet *meshes;
@property (nonatomic, retain) NSString *displayName;

// Derived
@property (nonatomic, retain) NSURL *itemURL;

@property (nonatomic, copy, readonly) NSString *itemName;
@property (nonatomic, copy, readonly) NSString *itemDirectory;

@property (nonatomic, retain) GLLModel *model;

@property (nonatomic, retain, readonly) NSArray *rootBoneTransformations;

- (GLLItemMesh *)settingsForMesh:(GLLModelMesh *)mesh;
- (GLLRenderParameterDescription *)descriptionForParameter:(NSString *)parameterName;


// Poses
- (BOOL)loadPose:(NSString *)poseDescription error:(NSError *__autoreleasing*)error;

@end

@interface GLLItem (CoreDataGeneratedAccessors)

- (void)insertObject:(GLLItemBone *)value inBoneTransformationsAtIndex:(NSUInteger)idx;
- (void)removeObjectFromBoneTransformationsAtIndex:(NSUInteger)idx;
- (void)insertBoneTransformations:(NSArray *)value atIndexes:(NSIndexSet *)indexes;
- (void)removeBoneTransformationsAtIndexes:(NSIndexSet *)indexes;
- (void)replaceObjectInBoneTransformationsAtIndex:(NSUInteger)idx withObject:(GLLItemBone *)value;
- (void)replaceBoneTransformationsAtIndexes:(NSIndexSet *)indexes withBoneTransformations:(NSArray *)values;
- (void)addBoneTransformationsObject:(GLLItemBone *)value;
- (void)removeBoneTransformationsObject:(GLLItemBone *)value;
- (void)addBoneTransformations:(NSOrderedSet *)values;
- (void)removeBoneTransformations:(NSOrderedSet *)values;
- (void)insertObject:(GLLItemMesh *)value inMeshesAtIndex:(NSUInteger)idx;
- (void)removeObjectFromMeshesAtIndex:(NSUInteger)idx;
- (void)insertMeshes:(NSArray *)value atIndexes:(NSIndexSet *)indexes;
- (void)removeMeshesAtIndexes:(NSIndexSet *)indexes;
- (void)replaceObjectInMeshesAtIndex:(NSUInteger)idx withObject:(GLLItemMesh *)value;
- (void)replaceMeshesAtIndexes:(NSIndexSet *)indexes withMeshes:(NSArray *)values;
- (void)addMeshesObject:(GLLItemMesh *)value;
- (void)removeMeshesObject:(GLLItemMesh *)value;
- (void)addMeshes:(NSOrderedSet *)values;
- (void)removeMeshes:(NSOrderedSet *)values;

@end
