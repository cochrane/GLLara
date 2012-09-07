//
//  GLLItemStorage.h
//  GLLara
//
//  Created by Torsten Kammer on 07.09.12.
//  Copyright (c) 2012 Torsten Kammer. All rights reserved.
//

#import <Foundation/Foundation.h>
#import <CoreData/CoreData.h>

@class GLLBoneTransformStorage, GLLMeshSettingsStorage;

@interface GLLItemStorage : NSManagedObject

@property (nonatomic, retain) NSData * itemURLBookmark;
@property (nonatomic) float scaleX;
@property (nonatomic) float scaleY;
@property (nonatomic) float scaleZ;
@property (nonatomic) BOOL isVisible;
@property (nonatomic, retain) NSOrderedSet *boneTransforms;
@property (nonatomic, retain) NSSet *meshSettings;
@end

@interface GLLItemStorage (CoreDataGeneratedAccessors)

- (void)insertObject:(GLLBoneTransformStorage *)value inBoneTransformsAtIndex:(NSUInteger)idx;
- (void)removeObjectFromBoneTransformsAtIndex:(NSUInteger)idx;
- (void)insertBoneTransforms:(NSArray *)value atIndexes:(NSIndexSet *)indexes;
- (void)removeBoneTransformsAtIndexes:(NSIndexSet *)indexes;
- (void)replaceObjectInBoneTransformsAtIndex:(NSUInteger)idx withObject:(GLLBoneTransformStorage *)value;
- (void)replaceBoneTransformsAtIndexes:(NSIndexSet *)indexes withBoneTransforms:(NSArray *)values;
- (void)addBoneTransformsObject:(GLLBoneTransformStorage *)value;
- (void)removeBoneTransformsObject:(GLLBoneTransformStorage *)value;
- (void)addBoneTransforms:(NSOrderedSet *)values;
- (void)removeBoneTransforms:(NSOrderedSet *)values;
- (void)addMeshSettingsObject:(GLLMeshSettingsStorage *)value;
- (void)removeMeshSettingsObject:(GLLMeshSettingsStorage *)value;
- (void)addMeshSettings:(NSSet *)values;
- (void)removeMeshSettings:(NSSet *)values;

@end
