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

NS_ASSUME_NONNULL_END
