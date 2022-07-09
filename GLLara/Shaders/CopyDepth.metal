//
//  CopyDepth.metal
//  GLLara
//
//  Created by Torsten Kammer on 07.07.22.
//  Copyright © 2022 Torsten Kammer. All rights reserved.
//

#include <metal_stdlib>
using namespace metal;

#include "../GLLResourceIDs.h"
#include "../GLLRenderParameters.h"
#include "../GLLVertexAttrib.h"

struct RasterizerData {
    float4 position [[position]];
    float2 screenSpacePosition;
};

vertex RasterizerData copyDepthVertex(uint vertexID [[ vertex_id ]],
                                     const device float2 * vertices [[ buffer(0) ]]) {
    RasterizerData out;
    
    float2 position = vertices[vertexID];
    out.screenSpacePosition = position;
    out.position = float4(position, 0, 1);
    
    return out;
}

struct FragmentResult {
    float4 color [[ color(0) ]];
    float depth [[ depth(any) ]];
};

fragment FragmentResult copyDepthFragment(RasterizerData in [[stage_in]],
                                          depth2d<float> depthPeelFrontBuffer [[ texture(GLLFragmentArgumentIndexTextureDepthPeelFront) ]],
                                          uint currentSample [[ sample_id ]]) {
    uint2 coords = uint2(in.position.xy);
    float frontDepth = depthPeelFrontBuffer.read(coords);
    
    FragmentResult result;
    result.color = float4(0);
    result.depth = frontDepth;
    
    return result;
}
