//
//  HUDTextDrawer.metal
//  GLLara
//
//  Created by Torsten Kammer on 24.07.22.
//  Copyright © 2022 Torsten Kammer. All rights reserved.
//

#include <metal_stdlib>
using namespace metal;

#include "../HUDShared.h"

struct RasterizerData {
    float4 position [[position]];
    float2 texCoord;
    float2 screenPosition;
};

vertex RasterizerData hudTextDrawerVertex(uint vertexID [[ vertex_id ]],
                                     const device HUDVertex * vertices [[ buffer(HUDVertexBufferData) ]],
                                         const device HUDVertexParams* params [[ buffer(HUDVertexBufferParams) ]]) {
    RasterizerData out;
    
    float2 position = (2 * vertices[vertexID].position / params->screenSize) - 1;
    
    out.position = float4(position, 0, 1);
    out.screenPosition = vertices[vertexID].position;
    out.texCoord = vertices[vertexID].texCoord;
    
    return out;
}

static float fraction(float in, float valueFor0, float valueFor1) {
    return clamp((in - valueFor0) / (valueFor1 - valueFor0), 0.0, 1.0);
}

fragment float4 hudTextDrawerFragment(RasterizerData in [[stage_in]],
                                      texture2d<float> texture [[ texture(HUDFragmentTextureBase) ]],
                                      const device HUDFragmentParams* params [[ buffer(HUDFragmentBufferParams) ]]) {
    constexpr sampler textureSampler(mag_filter::linear, min_filter::linear);
    float4 color = texture.sample(textureSampler, in.texCoord);
    
    color.a *= fraction(in.screenPosition.x, params->fadeOutEndBox[0].x, params->fadeOutStartBox[0].x);
    color.a *= fraction(in.screenPosition.y, params->fadeOutEndBox[0].y, params->fadeOutStartBox[0].y);
    color.a *= fraction(in.screenPosition.x, params->fadeOutEndBox[1].x, params->fadeOutStartBox[1].x);
    color.a *= fraction(in.screenPosition.y, params->fadeOutEndBox[1].y, params->fadeOutStartBox[1].y);
    
    return color * params->alpha;
}

