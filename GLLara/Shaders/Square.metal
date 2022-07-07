//
//  Square.metal
//  GLLara
//
//  Created by Torsten Kammer on 06.07.22.
//  Copyright © 2022 Torsten Kammer. All rights reserved.
//

#include <metal_stdlib>
using namespace metal;

struct RasterizerData {
    float4 position [[position]];
    float2 screenSpacePosition;
};

vertex RasterizerData squareVertex(uint vertexID [[ vertex_id ]],
                                     const device float2 * vertices [[ buffer(0) ]]) {
    RasterizerData out;
    
    float2 position = vertices[vertexID];
    out.screenSpacePosition = position;
    out.position = float4(position, 0, 1);
    
    return out;
}

fragment float4 squareFragment(RasterizerData in [[stage_in]], texture2d<float> texture [[ texture(0) ]]) {
    constexpr sampler textureSampler(mag_filter::linear, min_filter::linear);
    float2 texCoord = (in.screenSpacePosition + float2(1.0f)) * 0.5f;
    texCoord.y = 1.0f - texCoord.y;
    return texture.sample(textureSampler, texCoord);
}
