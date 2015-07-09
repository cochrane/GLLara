//
//  GLLModelBone.h
//  GLLara
//
//  Created by Torsten Kammer on 01.09.12.
//  Copyright (c) 2012 Torsten Kammer. All rights reserved.
//

#import <Foundation/Foundation.h>

#import "simd_types.h"

@class GLLASCIIScanner;
@class GLLModel;
@class TRInDataStream;

/*!
 * @abstract Description of a bone in a model.
 * @discussion A bone is a transformable entity; vertices belong to one or several bones, with different weights. The bone here is purely a static description and with default values. It does not contain any transformation information.
 */
@interface GLLModelBone : NSObject

// Bone without parent, children at position 0, 0, 0. No need to call setupParent afterwards.
- (id)init;

// Stream must be either a GLLASCIIScanner or a TRInDataStream.
- (id)initFromSequentialData:(id)stream partOfModel:(GLLModel *)model error:(NSError *__autoreleasing*)error;

// Export
- (NSString *)writeASCII;
- (NSData *)writeBinary;

@property (nonatomic, copy, readonly) NSString *name;
@property (nonatomic, assign, readonly) NSUInteger parentIndex;
@property (nonatomic, assign, readonly) float positionX;
@property (nonatomic, assign, readonly) float positionY;
@property (nonatomic, assign, readonly) float positionZ;
@property (nonatomic, assign, readonly) BOOL hasParent;

/*
 * Transformations for the bone.
 */
@property (nonatomic, assign) mat_float16 inversePositionMatrix;
@property (nonatomic, assign) mat_float16 positionMatrix;

@end
