//
//  HUDShared.h
//  GLLara
//
//  Created by Torsten Kammer on 25.07.22.
//  Copyright © 2022 Torsten Kammer. All rights reserved.
//

#ifndef HUDShared_h
#define HUDShared_h

#include <simd/simd.h>

struct HUDVertex {
    simd_float2 position;
    simd_float2 texCoord;
};

struct HUDVertexParams {
    simd_float2 screenSize;
};

struct HUDFragmentParams {
    float alpha;
    simd_float2 fadeOutStartBox[2];
    simd_float2 fadeOutEndBox[2];
};

enum HUDVertexBuffer {
    HUDVertexBufferData,
    HUDVertexBufferParams
};

enum HUDFragmentBuffer {
    HUDFragmentBufferParams
};

enum HUDFragmentTexture {
    HUDFragmentTextureBase
};

#endif /* HUDShared_h */
