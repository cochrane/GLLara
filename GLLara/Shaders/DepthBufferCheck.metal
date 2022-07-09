//
//  DepthBufferCheck.metal
//  GLLara
//
//  Created by Torsten Kammer on 09.07.22.
//  Copyright © 2022 Torsten Kammer. All rights reserved.
//

#include <metal_stdlib>
using namespace metal;

/*
 * Used only for debugging: This draws the depth buffer from the top
 * into a color texture in black and white
 */

struct RasterizerData {
    float4 position [[position]];
    float2 screenSpacePosition;
};

vertex RasterizerData depthBufferCheckVertex(uint vertexID [[ vertex_id ]],
                                     const device float2 * vertices [[ buffer(0) ]]) {
    RasterizerData out;
    
    float2 position = vertices[vertexID];
    out.screenSpacePosition = position;
    out.position = float4(position, 0, 1);
    
    return out;
}

fragment float4 depthBufferCheckFragment(RasterizerData in [[stage_in]],
                                          depth2d_ms<float> depthPeelFrontBuffer [[ texture(0) ]]) {
    uint height = depthPeelFrontBuffer.get_height();
    
    uint ourX = uint(in.position.x);
    
    float minDepthAtX = 1.0;
    const uint minY = height/2 - 10;
    const uint maxY = height/2 + 10;
    
    for (uint y = minY; y < maxY; y++) {
        minDepthAtX = min(minDepthAtX, depthPeelFrontBuffer.read(ushort2(ourX, y), 0));
    }
    
    float ourDepth = in.position.y / float(height - 1);
    ourDepth = (ourDepth - 0.5) * 2.0;
    
    return ourDepth >= minDepthAtX ? float4(0) : float4(1);
}
