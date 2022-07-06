//
//  GLLResourceIDs.h
//  GLLara
//
//  Created by Torsten Kammer on 10.04.22.
//  Copyright © 2022 Torsten Kammer. All rights reserved.
//

#ifndef GLLResourceIDs_h
#define GLLResourceIDs_h

#include <simd/simd.h>

typedef enum GLLVertexInputIndex {
    GLLVertexInputIndexViewProjection = 0,
    GLLVertexInputIndexTransforms,
    GLLVertexInputIndexLights,
    GLLVertexInputIndexViewport,
    GLLVertexInputIndexVertices
} GLLVertexInputIndex;

typedef enum GLLFragmentArgumentIndex {
    GLLFragmentArgumentIndexTextureDiffuse = 0,
    GLLFragmentArgumentIndexTextureSpecular,
    GLLFragmentArgumentIndexTextureEmission,
    GLLFragmentArgumentIndexTextureBump,
    GLLFragmentArgumentIndexTextureBump1,
    GLLFragmentArgumentIndexTextureBump2,
    GLLFragmentArgumentIndexTextureMask,
    GLLFragmentArgumentIndexTextureLightmap,
    GLLFragmentArgumentIndexTextureReflection,
    
    GLLFragmentArgumentIndexTextureMax,
    
    GLLFragmentArgumentIndexAmbientColor,
    GLLFragmentArgumentIndexDiffuseColor,
    GLLFragmentArgumentIndexSpecularColor,
    
    GLLFragmentArgumentIndexSpecularExponent,
    GLLFragmentArgumentIndexBump1UVScale,
    GLLFragmentArgumentIndexBump2UVScale,
    GLLFragmentArgumentIndexSpecularTextureScale,
    GLLFragmentArgumentIndexReflectionAmount,
    
    // Separate from other textures, not provided by us
    GLLFragmentArgumentIndexTextureDepthPeelFront,
} GLLFragmentArgumentIndex;

typedef enum GLLFragmentBufferIndex {
    GLLFragmentBufferIndexArguments = 1,
    GLLFragmentBufferIndexLights = 3
} GLLFragmentBufferIndex;

#endif /* GLLResourceIDs_h */
