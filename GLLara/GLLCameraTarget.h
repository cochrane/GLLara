//
//  GLLCameraTarget.h
//  GLLara
//
//  Created by Torsten Kammer on 09.09.12.
//  Copyright (c) 2012 Torsten Kammer. All rights reserved.
//

#import <Foundation/Foundation.h>
#import <CoreData/CoreData.h>

@class GLLBoneTransformation;

@interface GLLCameraTarget : NSManagedObject

@property (nonatomic, retain) NSString * name;
@property (nonatomic, retain) NSSet *bones;
@property (nonatomic, retain) NSSet *cameras;

// Derived
@property (nonatomic, retain, readonly) NSString *displayName;

@end

@interface GLLCameraTarget (CoreDataGeneratedAccessors)

- (void)addBonesObject:(GLLBoneTransformation *)value;
- (void)removeBonesObject:(GLLBoneTransformation *)value;
- (void)addBones:(NSSet *)values;
- (void)removeBones:(NSSet *)values;

- (void)addCamerasObject:(NSManagedObject *)value;
- (void)removeCamerasObject:(NSManagedObject *)value;
- (void)addCameras:(NSSet *)values;
- (void)removeCameras:(NSSet *)values;

@end
