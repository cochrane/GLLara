//
//  GLLItem.h
//  GLLara
//
//  Created by Torsten Kammer on 01.09.12.
//  Copyright (c) 2012 Torsten Kammer. All rights reserved.
//

#import <Foundation/Foundation.h>

#import "GLLVersion.h"
#import "simd_types.h"

@class TRInDataStream;
@class TROutDataStream;
@class GLLMesh;
@class GLLModel;

@interface GLLItem : NSObject

- (id)initWithModel:(GLLModel *)model;
- (id)initFromDataStream:(TRInDataStream *)stream baseURL:(NSURL *)url version:(GLLSceneVersion)version;

- (void)writeToStream:(TROutDataStream *)stream;

@property (nonatomic, copy, readonly) NSString *itemName;
@property (nonatomic, copy, readonly) NSString *itemDirectory;

@property (nonatomic, retain, readonly) GLLModel *model;

@property (nonatomic, assign) BOOL isVisible;

@property (nonatomic, assign) float scaleX;
@property (nonatomic, assign) float scaleY;
@property (nonatomic, assign) float scaleZ;

@property (nonatomic, retain, readonly) NSArray *boneTransformations;
@property (nonatomic, retain, readonly) NSArray *rootBoneTransformations;

- (void)getTransforms:(mat_float16 *)matrices maxCount:(NSUInteger)maxCount forMesh:(GLLMesh *)mesh;

@end
