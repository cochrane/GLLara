//
//  GLLItem.h
//  GLLara
//
//  Created by Torsten Kammer on 01.09.12.
//  Copyright (c) 2012 Torsten Kammer. All rights reserved.
//

#import <CoreData/CoreData.h>
#import <Foundation/Foundation.h>

#import "simd_types.h"

enum GLLItemChannelAssignment
{
	GLLNormalPos,
	GLLNormalNeg,
	GLLTangentUPos,
	GLLTangentUNeg,
	GLLTangentVPos,
	GLLTangentVNeg
};

@class TRInDataStream;
@class TROutDataStream;
@class GLLItemBone;
@class GLLItemMesh;
@class GLLModel;
@class GLLModelMesh;
@class GLLScene;
@class GLLRenderParameterDescription;

@interface GLLItem : NSManagedObject

// From Core Data
@property (nonatomic, retain) NSData * itemURLBookmark;
@property (nonatomic) float scaleX;
@property (nonatomic) float scaleY;
@property (nonatomic) float scaleZ;
@property (nonatomic) float rotationX;
@property (nonatomic) float rotationY;
@property (nonatomic) float rotationZ;
@property (nonatomic) float positionX;
@property (nonatomic) float positionY;
@property (nonatomic) float positionZ;
@property (nonatomic) BOOL isVisible;
@property (nonatomic, retain) NSOrderedSet *bones;
@property (nonatomic, retain) NSOrderedSet *meshes;
@property (nonatomic, retain) NSString *displayName;
@property (nonatomic) int16_t normalChannelAssignmentR;
@property (nonatomic) int16_t normalChannelAssignmentG;
@property (nonatomic) int16_t normalChannelAssignmentB;
@property (nonatomic, retain) GLLItem *parent;

// Derived
@property (nonatomic, retain) NSURL *itemURL;

@property (nonatomic, copy, readonly) NSString *itemName;
@property (nonatomic, copy, readonly) NSString *itemDirectory;

@property (nonatomic, retain) GLLModel *model;

@property (nonatomic, retain, readonly) NSArray *rootBones;

- (GLLItemMesh *)itemMeshForModelMesh:(GLLModelMesh *)mesh;

@property (nonatomic, readonly) mat_float16 modelTransform;

// Poses
- (BOOL)loadPose:(NSString *)poseDescription error:(NSError *__autoreleasing*)error;

- (GLLItemBone *)boneForName:(NSString *)name;

@end

@interface GLLItem (CoreDataGeneratedAccessors)

- (void)insertObject:(GLLItemBone *)value inBonesAtIndex:(NSUInteger)idx;
- (void)removeObjectFromBonesAtIndex:(NSUInteger)idx;
- (void)insertBones:(NSArray *)value atIndexes:(NSIndexSet *)indexes;
- (void)removeBonesAtIndexes:(NSIndexSet *)indexes;
- (void)replaceObjectInBonesAtIndex:(NSUInteger)idx withObject:(GLLItemBone *)value;
- (void)replaceBonesAtIndexes:(NSIndexSet *)indexes withBones:(NSArray *)values;
- (void)addBonesObject:(GLLItemBone *)value;
- (void)removeBonesObject:(GLLItemBone *)value;
- (void)addBones:(NSOrderedSet *)values;
- (void)removeBones:(NSOrderedSet *)values;
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
