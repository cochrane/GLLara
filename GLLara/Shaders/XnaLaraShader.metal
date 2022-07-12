//
//  XnaLaraShader.metal
//  GLLara
//
//  Created by Torsten Kammer on 12.04.22.
//  Copyright © 2022 Torsten Kammer. All rights reserved.
//


#include "../GLLResourceIDs.h"
#include "../GLLRenderParameters.h"
#include "../GLLVertexAttrib.h"

#include <metal_stdlib>
using namespace metal;

constant int numberOfUsedLights [[ function_constant(GLLFunctionConstantNumberOfUsedLights) ]];

constant bool hasNormal [[function_constant(GLLFunctionConstantHasNormal)]];
constant bool calculateTangentToWorld [[function_constant(GLLFunctionConstantCalculateTangentWorld)]];
constant bool useSkinning [[function_constant(GLLFunctionConstantUseSkinning)]];
constant bool hasDiffuseTexture [[ function_constant(GLLFunctionConstantHasDiffuseTexture) ]];
constant bool hasNormalDetailMap [[ function_constant(GLLFunctionConstantHasNormalDetailMap) ]];
constant bool isShadeless [[ function_constant(GLLFunctionConstantIsShadeless) ]];
constant bool hasSpecularLighting [[ function_constant(GLLFunctionConstantHasSpecularLighting) ]];
constant bool hasReflection [[ function_constant(GLLFunctionConstantHasReflection) ]];
constant bool hasSpecularTexture [[ function_constant(GLLFunctionConstantHasSpecularTexture) ]];
constant bool hasSpecularTextureScale [[ function_constant(GLLFunctionConstantHasSpecularTextureScale) ]];
constant bool hasDiffuseLighting [[ function_constant(GLLFunctionConstantHasDiffuseLighting) ]];
constant bool hasLightmap [[ function_constant(GLLFunctionConstantHasLightmap) ]];
constant bool hasEmission [[ function_constant(GLLFunctionConstantHasEmission) ]];
constant bool hasVertexColor [[ function_constant(GLLFunctionConstantHasVertexColor) ]];

constant bool hasDepthPeelFrontBuffer [[ function_constant(GLLFunctionConstantHasDepthPeelFrontBuffer) ]];

// TODO Probably need same for tangents when adding GLTF support
constant int numberOfTexCoordSets [[ function_constant(GLLFunctionConstantNumberOfTexCoordSets) ]];
constant bool hasTexCoord0 = numberOfTexCoordSets >= 1;
constant bool hasTexCoord1 = numberOfTexCoordSets >= 2;
constant bool hasTexCoord2 = numberOfTexCoordSets >= 3;
constant bool hasTexCoord3 = numberOfTexCoordSets >= 4;

constant bool hasTangentMatrixWorld = hasNormal && calculateTangentToWorld;
constant bool hasNormalWorld = hasNormal && !calculateTangentToWorld;

struct XnaLaraInputData {
    float3 position [[ attribute(GLLVertexAttribPosition) ]];
    float3 normal [[ attribute(GLLVertexAttribNormal) ]];
    float4 color [[ attribute(GLLVertexAttribColor) ]];
    ushort4 boneIndices [[ attribute(GLLVertexAttribBoneIndices), function_constant(useSkinning) ]];
    float4 boneWeights [[ attribute(GLLVertexAttribBoneWeights), function_constant(useSkinning) ]];
    float2 texCoord0 [[ attribute(GLLVertexAttribTexCoord0 + 2 * 0), function_constant(hasTexCoord0) ]];
    float2 texCoord1 [[ attribute(GLLVertexAttribTexCoord0 + 2 * 1), function_constant(hasTexCoord1) ]];
    float2 texCoord2 [[ attribute(GLLVertexAttribTexCoord0 + 2 * 2), function_constant(hasTexCoord2) ]];
    float2 texCoord3 [[ attribute(GLLVertexAttribTexCoord0 + 2 * 3), function_constant(hasTexCoord3) ]];
    float4 tangent [[ attribute(GLLVertexAttribTangent0 + 2 * 0), function_constant(hasTexCoord0) ]];
};

struct XnaLaraRasterizerData {
    float4 position [[ position ]];
    float4 screenPosition [[ function_constant(hasDepthPeelFrontBuffer) ]];
    float3 worldPosition;
    float4 color;
    float2 texCoord0 [[ function_constant(hasTexCoord0) ]];
    float2 texCoord1 [[ function_constant(hasTexCoord1) ]];
    float2 texCoord2 [[ function_constant(hasTexCoord2) ]];
    float2 texCoord3 [[ function_constant(hasTexCoord3) ]];
    float3 tangentToWorld0 [[ function_constant(hasTangentMatrixWorld) ]];
    float3 tangentToWorld1 [[ function_constant(hasTangentMatrixWorld) ]];
    float3 tangentToWorld2 [[ function_constant(hasTangentMatrixWorld) ]];
    float3 normalWorld [[ function_constant(hasNormalWorld) ]];
    
    float2 texCoordFor(int layer) {
        switch (layer) {
            case 0:
            default:
                return texCoord0;
            case 1:
                return texCoord1;
            case 2:
                return texCoord2;
            case 3:
                return texCoord3;
        }
    }
};

float3x3 upperLeft(float4x4 a) {
    return float3x3(a.columns[0].xyz, a.columns[1].xyz, a.columns[2].xyz);
}

vertex XnaLaraRasterizerData xnaLaraVertex(XnaLaraInputData in [[ stage_in ]],
                                           const device float4x4 *bones [[ buffer(GLLVertexInputIndexTransforms) ]],
                                           constant float4x4 & viewProjection [[ buffer(GLLVertexInputIndexViewProjection) ]]) {
    XnaLaraRasterizerData out;
    
    // Bones 0 is the permute for the normal values (TODO should it be?)
    float4x4 boneTransform;
    if (useSkinning) {
        boneTransform = bones[in.boneIndices[0] + 1] * in.boneWeights[0]
                        + bones[in.boneIndices[1] + 1] * in.boneWeights[1]
                        + bones[in.boneIndices[2] + 1] * in.boneWeights[2]
                        + bones[in.boneIndices[3] + 1] * in.boneWeights[3];
    } else {
        boneTransform = bones[1];
    }
    auto worldPosition = boneTransform * float4(in.position, 1.0);
    out.position = viewProjection * worldPosition;
    out.worldPosition = worldPosition.xyz;
    
    if (hasDepthPeelFrontBuffer) {
        out.screenPosition = out.position;
    }
    
    if (hasNormal) {
        if (calculateTangentToWorld && hasTexCoord0) {
            float3 normal = normalize(in.normal);
            float3 tangentU = normalize(in.tangent.xyz);
            float3 tangentV = normalize(cross(normal, tangentU) * sign(in.tangent.w));
            
            // TODO Should this be 'bone' instead of 'bones.transforms[0]'?
            float3x3 tangentToWorld = upperLeft(bones[1]) * float3x3(tangentU, tangentV, normal) * upperLeft(bones[0]);
            out.tangentToWorld0 = tangentToWorld.columns[0];
            out.tangentToWorld1 = tangentToWorld.columns[1];
            out.tangentToWorld2 = tangentToWorld.columns[2];
        } else {
            out.normalWorld = upperLeft(boneTransform) * in.normal;
        }
    }
    
    out.color = in.color;
    if (hasTexCoord0) {
        out.texCoord0 = in.texCoord0;
    }
    if (hasTexCoord1) {
        out.texCoord1 = in.texCoord1;
    }
    if (hasTexCoord2) {
        out.texCoord2 = in.texCoord2;
    }
    if (hasTexCoord3) {
        out.texCoord3 = in.texCoord3;
    }
    
    return out;
}

constant int texCoordSetDiffuse [[ function_constant(100 + GLLFragmentArgumentIndexTextureDiffuse) ]];
constant int texCoordSetSpecular [[ function_constant(100 + GLLFragmentArgumentIndexTextureSpecular) ]];
constant int texCoordSetEmission [[ function_constant(100 + GLLFragmentArgumentIndexTextureEmission) ]];
constant int texCoordSetBump [[ function_constant(100 + GLLFragmentArgumentIndexTextureBump) ]];
constant int texCoordSetBump1 [[ function_constant(100 + GLLFragmentArgumentIndexTextureBump1) ]];
constant int texCoordSetBump2 [[ function_constant(100 + GLLFragmentArgumentIndexTextureBump2) ]];
constant int texCoordSetMask [[ function_constant(100 + GLLFragmentArgumentIndexTextureMask) ]];
constant int texCoordSetLightmap [[ function_constant(100 + GLLFragmentArgumentIndexTextureLightmap) ]];
// reflection tex coord is calculated dynamically that's the whole point

struct XnaLaraFragmentArguments {
    texture2d<float> diffuseTexture [[ id(GLLFragmentArgumentIndexTextureDiffuse) ]];
    texture2d<float> specularTexture [[ id(GLLFragmentArgumentIndexTextureSpecular) ]];
    texture2d<float> emissionTexture [[ id(GLLFragmentArgumentIndexTextureEmission) ]];
    texture2d<float> bumpTexture [[ id(GLLFragmentArgumentIndexTextureBump) ]];
    texture2d<float> bump1Texture [[ id(GLLFragmentArgumentIndexTextureBump1) ]];
    texture2d<float> bump2Texture [[ id(GLLFragmentArgumentIndexTextureBump2) ]];
    texture2d<float> maskTexture [[ id(GLLFragmentArgumentIndexTextureMask) ]];
    texture2d<float> lightmapTexture [[ id(GLLFragmentArgumentIndexTextureLightmap) ]];
    texture2d<float> reflectionTexture [[ id(GLLFragmentArgumentIndexTextureReflection) ]];
    
    // Color for ambient lighting
    float4 ambientColor [[ id(GLLFragmentArgumentIndexAmbientColor) ]];
    // Color for diffuse lighting
    float4 diffuseColor [[ id(GLLFragmentArgumentIndexDiffuseColor) ]];
    // Color for specular lighting
    float4 specularColor [[ id(GLLFragmentArgumentIndexSpecularColor) ]];
    
    // Exponent for specular lighting
    float specularExponent [[ id(GLLFragmentArgumentIndexSpecularExponent) ]];
    // Scale for first detail bump map, used by some XNALara shaders
    float bump1UVScale [[ id(GLLFragmentArgumentIndexBump1UVScale) ]];
    // Scale for second detail bump map, used by some XNALara shaders
    float bump2UVScale [[ id(GLLFragmentArgumentIndexBump2UVScale) ]];
    // Scale for specular texture
    float specularTextureScale [[ id(GLLFragmentArgumentIndexSpecularTextureScale) ]];
    // Degree to which reflection (e.g. from environment map) gets blended in
    float reflectionAmount [[ id(GLLFragmentArgumentIndexReflectionAmount) ]];
};

fragment float4 xnaLaraFragment(XnaLaraRasterizerData in [[ stage_in ]],
        device XnaLaraFragmentArguments & arguments [[ buffer(GLLFragmentBufferIndexArguments) ]],
        device GLLLightsBuffer & lights [[ buffer(GLLFragmentBufferIndexLights) ]],
        sampler textureSampler [[ sampler(0) ]],
        depth2d<float> depthPeelFrontBuffer [[ texture(GLLFragmentArgumentIndexTextureDepthPeelFront), function_constant(hasDepthPeelFrontBuffer) ]],
        uint currentSample [[ sample_id ]]) {
    
    if (hasDepthPeelFrontBuffer) {
        float depth = in.position.z;
        uint2 coords = uint2(in.position.xy);
        float frontDepth = depthPeelFrontBuffer.read(coords);
        if (depth <= frontDepth) {
            discard_fragment();
            return float4(1, 0, 0.5, 1);
        }
    }
    
    // Calculate diffuse color
    float4 diffuseTextureColor = float4(1);
    if (hasDiffuseTexture && hasTexCoord0) {
        diffuseTextureColor = arguments.diffuseTexture.sample(textureSampler, in.texCoordFor(texCoordSetDiffuse));
    }
    float4 usedDiffuseColor = diffuseTextureColor;
    if (hasVertexColor) {
        usedDiffuseColor *= in.color;
    }
    
    // If Shadeless then return just this diffuse color
    if (isShadeless) {
        return usedDiffuseColor;
    }
    
    // Calculate normal
    float3 normal;
    if (hasNormal) {
        if (calculateTangentToWorld) {
            float3 normalMapColor = arguments.bumpTexture.sample(textureSampler, in.texCoordFor(texCoordSetBump)).xyz;
            if (hasNormalDetailMap) {
                float2 maskColor = arguments.maskTexture.sample(textureSampler, in.texCoordFor(texCoordSetMask)).xy;
                
                float3 detailNormalMap1 = arguments.bump1Texture.sample(textureSampler, in.texCoordFor(texCoordSetBump1) * arguments.bump1UVScale).xyz;
                normalMapColor += detailNormalMap1 * maskColor.x;
                
                float3 detailNormalMap2 = arguments.bump2Texture.sample(textureSampler, in.texCoordFor(texCoordSetBump2) * arguments.bump2UVScale).xyz;
                normalMapColor += detailNormalMap2 * maskColor.y;
            }
            float3 normalFromMap = normalMapColor * 2 - 1;
            float3x3 tangentMatrix(in.tangentToWorld0, in.tangentToWorld1, in.tangentToWorld2);
            normal = normalize(tangentMatrix * normalFromMap);
        } else {
            normal = in.normalWorld;
        }
    }
    
    // Calculate camera direction
    float3 cameraDirection = float3(0);
    if (hasReflection || hasSpecularLighting) {
        cameraDirection = normalize(lights.cameraPosition.xyz - in.worldPosition);
    }
    
    // Separate specular color
    float4 specularColor = arguments.specularColor;
    if (hasSpecularTexture) {
        float2 specularTextureCoord = in.texCoordFor(texCoordSetSpecular);
        if (hasSpecularTextureScale) {
            specularTextureCoord *= arguments.specularTextureScale;
        }
        specularColor *= arguments.specularTexture.sample(textureSampler, specularTextureCoord);
    }
    
    // Total color: Add in ambient; do this always, no ambient is represented by black ambient material color
    float4 color = lights.ambientColor * arguments.ambientColor * usedDiffuseColor;
    
    for (int i = 0; i < numberOfUsedLights; i++) {
        const device auto& light = lights.lights[i];
        
        // Diffuse term
        float diffuseFactor = max(dot(-normal, light.direction.xyz), 0.0f);
        if (hasDiffuseLighting) {
            color += usedDiffuseColor * arguments.diffuseColor * light.diffuseColor * diffuseFactor;
        }
        
        // Specular term
        if (hasSpecularLighting) {
            float3 reflectedLightDirection = reflect(light.direction.xyz, normal);
            float specularFactor = pow(max(dot(cameraDirection, reflectedLightDirection), 0.0f), arguments.specularExponent);
            if (diffuseFactor <= 0.001f) {
                specularFactor = 0.0f;
            }
            color += light.specularColor * specularColor * specularFactor;
        }
    }
    
    // Lightmap
    if (hasLightmap) {
        // TODO isn't lightmap the one that sometimes gets other tex coords?
        float2 coords = in.texCoordFor(texCoordSetLightmap);
        color *= arguments.lightmapTexture.sample(textureSampler, coords);
    }
    
    // Reflection
    if (hasReflection) {
        float3 reflectionDir = normalize(reflect(cameraDirection, normal));
        
        // Reflection dir now points at a sphere. We ignore the z component to get a circle. But we still have to scale it to get to the square XNAlara demands.
        float tanAlpha = reflectionDir.x/reflectionDir.y;
        float cotAlpha = reflectionDir.y/reflectionDir.x;
        float scaleFactor = sqrt(min(1.0f, tanAlpha*tanAlpha) + min(1.0f, cotAlpha*cotAlpha));
        float2 reflectionTexCoord = scaleFactor * reflectionDir.xy;
        float4 reflectionColor = arguments.reflectionTexture.sample(textureSampler, reflectionTexCoord * 0.5f + 0.5f);
        
        color = mix(color, reflectionColor, arguments.reflectionAmount);
    }
    
    // Emission
    if (hasEmission) {
        color += arguments.emissionTexture.sample(textureSampler, in.texCoordFor(texCoordSetEmission));
    }
    
    if (hasDepthPeelFrontBuffer) {
        // Apply alpha from diffuse texture
        color.a = diffuseTextureColor.a;
    } else {
        // Solid
        color.a = 1.0;
    }
    
    return color;
}
