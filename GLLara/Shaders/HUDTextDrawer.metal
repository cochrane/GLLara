//
//  HUDTextDrawer.metal
//  GLLara
//
//  Created by Torsten Kammer on 24.07.22.
//  Copyright © 2022 Torsten Kammer. All rights reserved.
//

#include <metal_stdlib>
using namespace metal;

struct InputData {
    float2 position;
    float2 texCoord;
};

struct RasterizerData {
    float4 position [[position]];
    float2 texCoord;
};

vertex RasterizerData hudTextDrawerVertex(uint vertexID [[ vertex_id ]],
                                     const device InputData * vertices [[ buffer(0) ]],
                                         const device float2* screenSize [[ buffer(1) ]]) {
    RasterizerData out;
    
    float2 size = *screenSize;
    float2 position = (2 * vertices[vertexID].position / size) - 1;
    
    out.position = float4(position, 0, 1);
    out.texCoord = vertices[vertexID].texCoord;
    
    return out;
}

fragment float4 hudTextDrawerFragment(RasterizerData in [[stage_in]], texture2d<float> texture [[ texture(0) ]]) {
    constexpr sampler textureSampler(mag_filter::linear, min_filter::linear);
    return texture.sample(textureSampler, in.texCoord);
}

