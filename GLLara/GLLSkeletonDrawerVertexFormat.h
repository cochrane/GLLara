//
//  GLLSkeletonDrawerVertexFormat.h
//  GLLara
//
//  Created by Torsten Kammer on 10.04.22.
//  Copyright © 2022 Torsten Kammer. All rights reserved.
//

#ifndef GLLSkeletonDrawerVertexFormat_h
#define GLLSkeletonDrawerVertexFormat_h

#include <simd/simd.h>

#include "GLLResourceIDs.h"

typedef struct GLLSkeletonDrawerVertex {
    vector_float3 position;
    vector_uchar4 color;
} GLLSkeletonDrawerVertex;

#endif /* GLLSkeletonDrawerVertexFormat_h */
