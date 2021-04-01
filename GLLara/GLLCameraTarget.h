//
//  GLLCameraTarget.h
//  GLLara
//
//  Created by Torsten Kammer on 09.09.12.
//  Copyright (c) 2012 Torsten Kammer. All rights reserved.
//

#import <Foundation/Foundation.h>
#import <CoreData/CoreData.h>

#import "simd_types.h"

@class GLLItemBone;

@interface GLLCameraTarget : NSManagedObject

@property (nonatomic, retain) NSString * name;
@property (nonatomic, retain) NSSet<GLLItemBone *> *bones;
@property (nonatomic, retain) NSSet *cameras;

// Derived
@property (nonatomic, retain, readonly) NSString *displayName;
@property (nonatomic, assign, readonly) vec_float4 position;

@end

@interface GLLCameraTarget (CoreDataGeneratedAccessors)

- (void)addBonesObject:(GLLItemBone *)value;
- (void)removeBonesObject:(GLLItemBone *)value;
- (void)addBones:(NSSet *)values;
- (void)removeBones:(NSSet *)values;

- (void)addCamerasObject:(NSManagedObject *)value;
- (void)removeCamerasObject:(NSManagedObject *)value;
- (void)addCameras:(NSSet *)values;
- (void)removeCameras:(NSSet *)values;

@end
