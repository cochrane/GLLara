//
//  GLLVertexAttribAccessor.h
//  GLLara
//
//  Created by Torsten Kammer on 06.04.21.
//  Copyright © 2021 Torsten Kammer. All rights reserved.
//

#ifndef __METAL__

#import <Foundation/Foundation.h>

#endif

/*!
 * @abstract Defines the indices for the different vertex attribute arrays.
 */
#ifdef __cplusplus
enum GLLVertexAttribSemantic {
#else
typedef NS_ENUM(NSInteger, GLLVertexAttribSemantic) {
#endif
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

#ifdef __cplusplus
enum GLLCullFaceMode {
#else
typedef NS_ENUM(NSInteger, GLLCullFaceMode) {
#endif
    GLLCullCounterClockWise,
    GLLCullClockWise,
    GLLCullNone
};
