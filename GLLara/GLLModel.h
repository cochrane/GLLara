//
//  GLLModel.h
//  GLLara
//
//  Created by Torsten Kammer on 31.08.12.
//  Copyright (c) 2012 Torsten Kammer. All rights reserved.
//

#import <Foundation/Foundation.h>

enum GLLModelLoadingErrorCodes
{
	GLLModelLoadingError_PrematureEndOfFile,
	GLLModelLoadingError_IndexOutOfRange,
	GLLModelLoadingError_CircularReference,
	GLLModelLoadingError_FileTypeNotSupported,
	GLLModelLoadingError_ParametersNotFound
};
extern NSString *GLLModelLoadingErrorDomain;

@class GLLCameraTargetDescription;
@class GLLModelBone;
@class GLLModelMesh;
@class GLLModelParams;

/*!
 * @abstract A renderable object.
 * @discussion A GLLModel corresponds to one mesh file (which actually contains many meshes; this is a bit confusing) and describes its graphics contexts. It contains some default transformations, but does not store poses and the like.
 */
@interface GLLModel : NSObject

/*!
 * @abstract Returns a model with a given URL, returning a cached instance if one exists.
 * @discussion Since a model is immutable here, it can be shared as much as necessary. This method uses an internal cache to share objects. Note that a model can be evicted from this cache again, if nobody is using it.
 */
+ (id)cachedModelFromFile:(NSURL *)file parent:(GLLModel *)parent error:(NSError *__autoreleasing*)error;

@property (nonatomic, copy) NSURL *baseURL;

@property (nonatomic, retain) GLLModelParams *parameters;

@property (nonatomic, assign, readonly) BOOL hasBones;

@property (nonatomic, copy) NSArray<GLLModelBone *> *bones;
@property (nonatomic, copy) NSArray<GLLModelMesh *> *meshes;

@property (nonatomic, copy, readonly) NSArray<GLLModelBone *> *rootBones;

@property (nonatomic, copy, readonly) NSArray<GLLCameraTargetDescription *> *cameraTargetNames;

- (GLLModelBone *)boneForName:(NSString *)name;

@end
