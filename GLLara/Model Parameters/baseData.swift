//
//  baseData.swift
//  GLLara
//
//  Created by Torsten Kammer on 03.07.22.
//  Copyright © 2022 Torsten Kammer. All rights reserved.
//

import Foundation

func registerModelParams() {
    let baseData = try! GLLModelParams(plistData: GLLModelParams.PlistDataTransferObject(shaders: [
    GLLShaderBase(name: "default", vertex: "xnaLaraVertex", fragment: "xnaLaraFragment", children: [
        GLLShaderModule(name: "skinning", requiredVertexAttributes: ["boneIndices", "boneWeights"], activeBoolConstants: [ .useSkinning ]),
        GLLShaderModule(name: "diffuseTexture", textureUniforms: [ "diffuseTexture" ], activeBoolConstants: [ .hasDiffuseTexture, .hasTexCoord0 ]),
        GLLShaderModule(name: "vertexColor", requiredVertexAttributes: [ "vertexColor" ], activeBoolConstants: [ .hasVertexColor ]),
        GLLShaderModule(name: "normalMap", textureUniforms: [ "bumpTexture" ], requiredVertexAttributes: [ "normal" ], activeBoolConstants: [ .calculateTangentWorld, .hasNormal
            ], children: [
                GLLShaderModule(name: "normalDetailMap", textureUniforms: [ "bump1Texture", "bump2Texture", "maskTexture"], parameterUniforms: [ "bump1UVScale", "bump2UVScale"], activeBoolConstants: [ .hasNormalDetailMap ])
        ]),
        GLLShaderModule(name: "lighting", requiredVertexAttributes: [ "normal" ], children: [
            GLLShaderModule(name: "diffuseLighting", activeBoolConstants: [ .hasDiffuseLighting ]),
            GLLShaderModule(name: "specularLighting", parameterUniforms: [ "bumpSpecularGloss", "bumpSpecularAmount" ], activeBoolConstants: [ .hasSpecularLighting ], children: [
                GLLShaderModule(name: "specularTexture", textureUniforms: [ "specularTexture" ], activeBoolConstants: [ .hasSpecularTexture ], children: [
                    GLLShaderModule(name: "specularTextureScale", parameterUniforms: [ "specularTextureScale" ], activeBoolConstants: [ .hasSpecularTextureScale ]),
                ])
            ]),
        ]),
        GLLShaderModule(name: "reflection", textureUniforms: [ "reflectionTexture" ], requiredVertexAttributes: [ "normal" ], activeBoolConstants: [ .hasReflection, .hasNormal ]),
        GLLShaderModule(name: "lightmap", textureUniforms: [ "lightmapTexture" ], activeBoolConstants: [ .hasLightmap ]),
        GLLShaderModule(name: "emission", textureUniforms: [ "emissionTexture" ], activeBoolConstants: [ .hasEmission ])
    ])
    ], renderParameterDescriptions: [
        "ambientColor": GLLRenderParameterDescription(titleKey: "Ambient Color", descriptionKey: "Color of the unlit parts", type: .color),
        "diffuseColor": GLLRenderParameterDescription(titleKey: "Diffuse Color", descriptionKey: "Color of the lit parts", type: .color),
        "specularColor": GLLRenderParameterDescription(titleKey: "Specular Color", descriptionKey: "Color of the highlights", type: .color),
        "specularExponent": GLLRenderParameterDescription(titleKey: "Specular Exponent", descriptionKey: "Sharpness of the highlights. Higher values produce smaller, more focused highlights.", max: 1000.0),
        "bumpSpecularGloss": GLLRenderParameterDescription(titleKey: "Specular Exponent", descriptionKey: "Sharpness of the highlights. Higher values produce smaller, more focused highlights.", max: 1000.0),
        "specularTextureScale": GLLRenderParameterDescription(titleKey: "Specular Texture Scale", descriptionKey: "How often the specular texture is repeated over the model. I have no idea why anyone would need this, but XPS supports it, so here we are.", min: 0.01, max: 32.0),
        "bump1UVScale": GLLRenderParameterDescription(titleKey: "Bump Detail UV Scale 1", descriptionKey: "How often the first detail texture is repeated over the model. Higher values mean smaller structures.", min: 0.01, max: 32.0),
        "bump2UVScale": GLLRenderParameterDescription(titleKey: "Bump Detail UV Scale 2", descriptionKey: "How often the second detail texture is repeated over the model. Higher values mean smaller structures.", min: 0.01, max: 32.0),
        "reflectionAmount": GLLRenderParameterDescription(titleKey: "Reflection", descriptionKey: "Blends the color with the environment map.", max: 1.0),
        "bumpSpecularAmount": GLLRenderParameterDescription(titleKey: "Bump Specular Amount", descriptionKey: "Intensity of the highlights.", max: 1.0),
    ]))
    GLLModelParams.register(parameters: baseData, forName: "baseData")
}
