//
//  GLLItem.h
//  GLLara
//
//  Created by Torsten Kammer on 01.09.12.
//  Copyright (c) 2012 Torsten Kammer. All rights reserved.
//

#import <Foundation/Foundation.h>

#import "GLLVersion.h"
#import "GLLSourceListItem.h"
#import "simd_types.h"

@class TRInDataStream;
@class TROutDataStream;
@class GLLMesh;
@class GLLMeshSettings;
@class GLLModel;
@class GLLScene;

@interface GLLItem : NSObject <GLLSourceListItem>

- (id)initWithModel:(GLLModel *)model scene:(GLLScene *)scene;
- (id)initFromDataStream:(TRInDataStream *)stream baseURL:(NSURL *)url version:(GLLSceneVersion)version scene:(GLLScene *)scene;

- (void)writeToStream:(TROutDataStream *)stream;

@property (nonatomic, weak, readonly) GLLScene *scene;

@property (nonatomic, copy, readonly) NSString *itemName;
@property (nonatomic, copy, readonly) NSString *itemDirectory;
@property (nonatomic, copy, readonly) NSString *displayName;

@property (nonatomic, retain, readonly) GLLModel *model;

@property (nonatomic, assign) BOOL isVisible;

@property (nonatomic, assign) float scaleX;
@property (nonatomic, assign) float scaleY;
@property (nonatomic, assign) float scaleZ;

@property (nonatomic, retain, readonly) NSArray *boneTransformations;
@property (nonatomic, retain, readonly) NSArray *rootBoneTransformations;
@property (nonatomic, retain, readonly) NSArray *meshSettings;

- (GLLMeshSettings *)settingsForMesh:(GLLMesh *)mesh;

- (void)getTransforms:(mat_float16 *)matrices maxCount:(NSUInteger)maxCount forMesh:(GLLMesh *)mesh;

- (void)changedPosition;

@end
