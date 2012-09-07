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
@property (nonatomic, retain) NSNumber * scaleX;
@property (nonatomic, retain) NSNumber * scaleY;
@property (nonatomic, retain) NSNumber * scaleZ;
@property (nonatomic, retain) NSNumber * isVisible;
@property (nonatomic, retain) NSOrderedSet *boneTransformations;
@property (nonatomic, retain) NSOrderedSet *meshSettings;
@end

@interface GLLItemStorage (CoreDataGeneratedAccessors)

- (void)insertObject:(GLLBoneTransformStorage *)value inBoneTransformationsAtIndex:(NSUInteger)idx;
- (void)removeObjectFromBoneTransformationsAtIndex:(NSUInteger)idx;
- (void)insertBoneTransformations:(NSArray *)value atIndexes:(NSIndexSet *)indexes;
- (void)removeBoneTransformationsAtIndexes:(NSIndexSet *)indexes;
- (void)replaceObjectInBoneTransformationsAtIndex:(NSUInteger)idx withObject:(GLLBoneTransformStorage *)value;
- (void)replaceBoneTransformationsAtIndexes:(NSIndexSet *)indexes withBoneTransformations:(NSArray *)values;
- (void)addBoneTransformationsObject:(GLLBoneTransformStorage *)value;
- (void)removeBoneTransformationsObject:(GLLBoneTransformStorage *)value;
- (void)addBoneTransformations:(NSOrderedSet *)values;
- (void)removeBoneTransformations:(NSOrderedSet *)values;
- (void)insertObject:(GLLMeshSettingsStorage *)value inMeshSettingsAtIndex:(NSUInteger)idx;
- (void)removeObjectFromMeshSettingsAtIndex:(NSUInteger)idx;
- (void)insertMeshSettings:(NSArray *)value atIndexes:(NSIndexSet *)indexes;
- (void)removeMeshSettingsAtIndexes:(NSIndexSet *)indexes;
- (void)replaceObjectInMeshSettingsAtIndex:(NSUInteger)idx withObject:(GLLMeshSettingsStorage *)value;
- (void)replaceMeshSettingsAtIndexes:(NSIndexSet *)indexes withMeshSettings:(NSArray *)values;
- (void)addMeshSettingsObject:(GLLMeshSettingsStorage *)value;
- (void)removeMeshSettingsObject:(GLLMeshSettingsStorage *)value;
- (void)addMeshSettings:(NSOrderedSet *)values;
- (void)removeMeshSettings:(NSOrderedSet *)values;
@end
