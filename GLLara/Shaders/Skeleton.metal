//
//  Skeleton.metal
//  GLLara
//
//  Created by Torsten Kammer on 10.04.22.
//  Copyright © 2022 Torsten Kammer. All rights reserved.
//

#include <metal_stdlib>
using namespace metal;

#include "../GLLSkeletonDrawerVertexFormat.h"

struct RasterizerData {
    float4 position [[position]];
    float4 color;
};

vertex RasterizerData skeletonVertex(uint vertexID [[ vertex_id ]],
                                     constant float4x4 & viewProjection [[ buffer(GLLVertexInputIndexTransforms) ]],
                                     const device GLLSkeletonDrawerVertex * vertices [[ buffer(GLLVertexInputIndexVertices) ]]) {
    RasterizerData out;
    
    float4 position = float4(vertices[vertexID].position, 1.0);
    out.position = viewProjection * position;
    
    // I feel like there should be a nicer option for this
    out.color = float4(vertices[vertexID].color) / 255.0f;
    
    return out;
}

fragment float4 skeletonFragment(RasterizerData in [[stage_in]]) {
    return in.color;
}
