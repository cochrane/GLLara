//
//  GLLVertexAttribAccessor.h
//  GLLara
//
//  Created by Torsten Kammer on 06.04.21.
//  Copyright © 2021 Torsten Kammer. All rights reserved.
//

#ifdef __METAL_MACOS__

#ifndef NS_ASSUME_NONNULL_BEGIN
#define NS_ASSUME_NONNULL_BEGIN
#endif

#ifndef NS_ASSUME_NONNULL_END
#define NS_ASSUME_NONNULL_END
#endif

#define NS_ENUM(a, b) enum b: a
typedef int NSInteger;

#else

#import <Foundation/Foundation.h>

#endif

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
    GLLVertexAttribPadding,
    GLLVertexAttribBoneDataOffsetLength,
    
    GLLVertexAttribTexCoord0,
    GLLVertexAttribTangent0,
};

typedef NS_ENUM(NSInteger, GLLCullFaceMode)
{
    GLLCullCounterClockWise,
    GLLCullClockWise,
    GLLCullNone
};

NS_ASSUME_NONNULL_END
