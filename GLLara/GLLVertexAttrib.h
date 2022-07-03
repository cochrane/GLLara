//
//  GLLVertexAttribAccessor.h
//  GLLara
//
//  Created by Torsten Kammer on 06.04.21.
//  Copyright © 2021 Torsten Kammer. All rights reserved.
//

#import <Foundation/Foundation.h>
#import <Metal/Metal.h>

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
    GLLVertexAttribPadding
};

typedef NS_ENUM(NSInteger, GLLCullFaceMode)
{
    GLLCullCounterClockWise,
    GLLCullClockWise,
    GLLCullNone
};

@interface GLLVertexAttrib : NSObject<NSCopying>

- (instancetype)initWithSemantic:(GLLVertexAttribSemantic)semantic layer:(NSInteger) layer format:(MTLVertexFormat) format;

@property (nonatomic, readonly, assign) GLLVertexAttribSemantic semantic;
@property (nonatomic, readonly, assign) NSInteger layer;

@property (nonatomic, readonly, assign) NSInteger numberOfElements;
@property (nonatomic, readonly, assign) NSInteger sizeInBytes;

@property (nonatomic, readonly, assign) NSInteger identifier;
@property (nonatomic, readonly, assign) MTLVertexFormat mtlFormat;

// Sort according to semantic and layer. Size and type are ignored
- (NSComparisonResult)compare:(GLLVertexAttrib *)other;

@end

NS_ASSUME_NONNULL_END
