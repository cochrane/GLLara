//
//  GLLRenderParameters.h
//  GLLara
//
//  Created by Torsten Kammer on 10.04.22.
//  Copyright © 2022 Torsten Kammer. All rights reserved.
//

#ifndef GLLRenderParameters_h
#define GLLRenderParameters_h

#ifndef __cplusplus
#import <Foundation/Foundation.h>
#endif

#include <simd/simd.h>

typedef struct GLLLightBuffer {
    vector_float4 diffuseColor;
    vector_float4 specularColor;
    vector_float4 direction;
} GLLLightBuffer;

typedef struct GLLLightsBuffer {
    vector_float4 cameraPosition;
    vector_float4 ambientColor;
    GLLLightBuffer lights[3];
} GLLLightsBuffer;

#ifdef __cplusplus
enum GLLFunctionConstant {
#else
typedef NS_ENUM(NSInteger, GLLFunctionConstant) {
#endif
    GLLFunctionConstantHasNormal = 0,
    GLLFunctionConstantCalculateTangentWorld,
    GLLFunctionConstantUseSkinning,
    GLLFunctionConstantHasDiffuseTexture,
    GLLFunctionConstantHasNormalDetailMap,
    GLLFunctionConstantIsShadeless,
    GLLFunctionConstantHasReflection,
    GLLFunctionConstantHasSpecularLighting,
    GLLFunctionConstantHasSpecularTexture,
    GLLFunctionConstantHasSpecularTextureScale,
    GLLFunctionConstantHasDiffuseLighting,
    GLLFunctionConstantHasLightmap,
    GLLFunctionConstantHasEmission,
    GLLFunctionConstantHasVertexColor,
    
    GLLFunctionConstantBoolMax,
    
    GLLFunctionConstantNumberOfUsedLights,
    GLLFunctionConstantNumberOfTexCoordSets,
    
    GLLFunctionConstantMax
};

#endif /* GLLRenderParameters_h */
