//
//  GLLVertexAttribAccessor.h
//  GLLara
//
//  Created by Torsten Kammer on 06.04.21.
//  Copyright © 2021 Torsten Kammer. All rights reserved.
//

#import <Foundation/Foundation.h>

NS_ASSUME_NONNULL_BEGIN

/*!
 * @abstract Defines the indices for the different vertex attribute arrays.
 */
typedef NS_ENUM(NSInteger, GLLVertexAttribSemantic)
{
    GLLVertexAttribPosition,
    GLLVertexAttribNormal,
    GLLVertexAttribColor,
    GLLVertexAttribBoneIndices,
    GLLVertexAttribBoneWeights,
    GLLVertexAttribTexCoord0,
    GLLVertexAttribTangent0,
};

typedef NS_ENUM(NSInteger, GLLVertexAttribSize) {
    GLLVertexAttribSizeScalar,
    GLLVertexAttribSizeVec2,
    GLLVertexAttribSizeVec3,
    GLLVertexAttribSizeVec4,
    GLLVertexAttribSizeMat2,
    GLLVertexAttribSizeMat3,
    GLLVertexAttribSizeMat4
};

typedef NS_ENUM(NSInteger, GLLVertexAttribComponentType) {
    GllVertexAttribComponentTypeByte = 5120,
    GllVertexAttribComponentTypeUnsignedByte = 5121,
    GllVertexAttribComponentTypeShort = 5122,
    GllVertexAttribComponentTypeUnsignedShort = 5123,
    GllVertexAttribComponentTypeInt = 5124,
    GllVertexAttribComponentTypeUnsignedInt = 5125,
    GllVertexAttribComponentTypeFloat = 5126,
    GllVertexAttribComponentTypeHalfFloat = 0x140B,
    GllVertexAttribComponentTypeInt2_10_10_10_Rev = 0x8D9F // Must be vec4
};

@interface GLLVertexAttrib : NSObject<NSCopying>

- (instancetype)initWithSemantic:(GLLVertexAttribSemantic)semantic layer:(NSUInteger) layer size:(GLLVertexAttribSize)size componentType:(GLLVertexAttribComponentType)type;

@property (nonatomic, readonly, assign) GLLVertexAttribSemantic semantic;
@property (nonatomic, readonly, assign) NSUInteger layer;
@property (nonatomic, readonly, assign) GLLVertexAttribSize size;
@property (nonatomic, readonly, assign) GLLVertexAttribComponentType type;

@property (nonatomic, readonly, assign) NSUInteger numberOfElements;
@property (nonatomic, readonly, assign) NSUInteger sizeInBytes;

// Sort according to semantic and layer. Size and type are ignored
- (NSComparisonResult)compare:(GLLVertexAttrib *)other;

@end

NS_ASSUME_NONNULL_END
