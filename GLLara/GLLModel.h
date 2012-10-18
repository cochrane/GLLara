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
	GLLModelLoadingError_FileTypeNotSupported
};
extern NSString *GLLModelLoadingErrorDomain;

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
+ (id)cachedModelFromFile:(NSURL *)file error:(NSError *__autoreleasing*)error;


- (id)initBinaryFromFile:(NSURL *)file error:(NSError *__autoreleasing*)error;
- (id)initBinaryFromData:(NSData *)data parameters:(GLLModelParams *)parameters baseURL:(NSURL *)baseURL error:(NSError *__autoreleasing*)error;
- (id)initASCIIFromFile:(NSURL *)file error:(NSError *__autoreleasing*)error;
- (id)initASCIIFromString:(NSString *)source parameters:(GLLModelParams *)parameters baseURL:(NSURL *)baseURL error:(NSError *__autoreleasing*)error;

@property (nonatomic, copy) NSURL *baseURL;

@property (nonatomic, retain) GLLModelParams *parameters;

@property (nonatomic, assign, readonly) BOOL hasBones;

@property (nonatomic, copy) NSArray *bones;
@property (nonatomic, copy) NSArray *meshes;

@property (nonatomic, copy) NSArray *rootBones;

@property (nonatomic, copy) NSArray *cameraTargetNames;
- (NSArray *)boneNamesForCameraTarget:(NSString *)target;

@end
