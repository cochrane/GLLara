/*
 * Combined fragment shader implementing all features, choosable via defines.
 * Defines:
 * - LIGHTMAP: Use lightmap, adding new sampler.
 *
 * Defines that are chosen by the application (not the shader config):
 * - USE_ALPHA_TEST: whether alpha test is implemented.
 * - NUMBER_OF_LIGHTS: How many lights there are. Defined to 3 if not present
 */

#if !defined(NUMBER_OF_LIGHTS)
#define NUMBER_OF_LIGHTS 3
#endif

in vec4 outColor;
$$in vec2 outTexCoord%ld;
in vec3 positionWorld;
#ifdef HAVE_NORMAL_WORLD
#ifdef CALCULATE_TANGENT_TO_WORLD
$$in mat3 tangentToWorld%ld;
#else
in vec3 normalWorld;
#endif
#endif

out vec4 screenColor;

#ifdef DIFFUSE_TEXTURE
uniform sampler2D diffuseTexture;
#endif
#ifdef CALCULATE_TANGENT_TO_WORLD
uniform sampler2D bumpTexture;
#ifdef NORMAL_DETAIL_MAP
uniform sampler2D bump1Texture;
uniform sampler2D bump2Texture;
uniform sampler2D maskTexture;
#endif
#endif
#ifdef LIGHTMAP
uniform sampler2D lightmapTexture;
#endif
#ifdef EMISSION
uniform sampler2D emissionTexture;
#endif
#ifdef SEPARATE_SPECULAR_TEXTURE
uniform sampler2D specularTexture;
#endif
#ifdef REFLECTION
uniform sampler2D reflectionTexture;
#endif

struct Light {
    vec4 diffuseColor;
    vec4 specularColor;
    vec4 direction;
};

layout(std140) uniform LightData {
    vec4 cameraPosition;
    vec4 ambientColor;
    Light lights[NUMBER_OF_LIGHTS];
} lightData;

#ifdef RENDER_PARAMETERS
uniform RenderParameters {
#ifdef AMBIENT_COLOR
    vec4 ambientColor;
#endif
#ifdef DIFFUSE_COLOR_VALUE
    vec4 diffuseColor;
#endif
    
#ifdef SPECULAR
#ifdef SPECULAR_COLOR_VALUE
    vec4 specularColor;
    float specularExponent;
#else
    // For MATERIAL_PARAMETERS, the gloss is given as specularExponent instead.
    float bumpSpecularGloss;
    float bumpSpecularAmount;
#endif
#endif
    
#ifdef NORMAL_DETAIL_MAP
    float bump1UVScale;
    float bump2UVScale;
#endif
    
#ifdef REFLECTION
    float reflectionAmount;
#endif

#ifdef SPECULAR_TEXTURE_SCALE
    float specularTextureScale;
#endif
} parameters;
#endif

#ifdef USE_ALPHA_TEST
layout(std140) uniform AlphaTest {
    uint mode; // 0 - none, 1 - pass if greater than, 2 - pass if less than.
    float reference;
} alphaTest;
#endif

void main()
{
    // Find diffuse texture and do alpha test.
#ifdef DIFFUSE_TEXTURE
    vec4 diffuseTexColor = texture(diffuseTexture, diffuseTextureCoord);
#else
    vec4 diffuseTexColor = vec4(1);
#endif
    
#ifdef USE_ALPHA_TEST
    if ((alphaTest.mode == 1U && diffuseTexColor.a <= alphaTest.reference) || (alphaTest.mode == 2U && diffuseTexColor.a >= alphaTest.reference))
        discard;
#endif
    
#ifdef CALCULATE_TANGENT_TO_WORLD
    // Calculate normal
    vec4 normalMap = texture(bumpTexture, bumpTextureCoord);
#ifdef NORMAL_DETAIL_MAP
    vec4 detailNormalMap1 = texture(bump1Texture, bump1TextureCoord * parameters.bump1UVScale);
    vec4 detailNormalMap2 = texture(bump2Texture, bump2TextureCoord * parameters.bump2UVScale);
    vec4 maskColor = texture(maskTexture, maskTextureCoord);
    
    vec3 normalFromMap = (normalMap.rgb + detailNormalMap1.rgb * maskColor.r + detailNormalMap2.rgb * maskColor.g) * 2 - 1;
#else
    vec3 normalFromMap = normalMap.rgb * 2 - 1;
#endif
    vec3 normalWorld = normalize(tangentToWorld0 * normalFromMap);
#endif
    
#ifdef CAMERA_DIRECTION
    // Direction to camera
    vec3 cameraDirection = normalize(lightData.cameraPosition.xyz - positionWorld);
#endif
#ifdef SEPARATE_SPECULAR_TEXTURE
    // Separate specular color
#ifdef SPECULAR_TEXTURE_SCALE
    vec4 specularColor = texture(specularTexture, specularTextureCoord * parameters.specularTextureScale);
#else
    vec4 specularColor = texture(specularTexture, specularTextureCoord);
#endif
#endif
    
    // Base diffuse color
#ifdef VERTEX_COLOR
    vec4 diffuseColor = diffuseTexColor * outColor;
#else
    vec4 diffuseColor = diffuseTexColor;
#endif
    
    vec4 color = vec4(0);
#ifdef SHADELESS
    color = diffuseColor;
#endif
#ifdef AMBIENT_COLOR
    color += lightData.ambientColor * diffuseColor;
#ifdef MATERIAL_PARAMETERS
    color *= parameters.ambientColor;
#endif
#endif
    for (int i = 0; i < NUMBER_OF_LIGHTS; i++)
    {
#ifdef DIFFUSE
        // Diffuse term
        float diffuseFactor = max(dot(-normalWorld, lightData.lights[i].direction.xyz), 0);
#ifdef DIFFUSE_COLOR_VALUE
        color += diffuseColor * lightData.lights[i].diffuseColor * diffuseFactor * parameters.diffuseColor;
#else
        color += diffuseColor * lightData.lights[i].diffuseColor * diffuseFactor;
#endif
#endif
        
#ifdef SPECULAR
        // TODO: This has grown historically, there's really no reason for these two different names here. But changing it now might impact save files.
#ifdef MATERIAL_PARAMETERS
        float exponent = parameters.specularExponent;
#else
        float exponent = parameters.bumpSpecularGloss;
#endif
        
        // Specular term
        vec3 reflectedLightDirection = reflect(lightData.lights[i].direction.xyz, normalWorld);
        float specularFactor = pow(max(dot(cameraDirection, reflectedLightDirection), 0), exponent);
#ifndef SPECULAR_COLOR_VALUE
        // TODO: Would make sense to get rid of this amount factor and just offer users a specular color
        specularFactor *= parameters.bumpSpecularAmount; // In MTL: Fold into RenderParameters/specularColor
#endif
        if (diffuseFactor <= 0.001) specularFactor = 0;
        vec4 specularContribution = lightData.lights[i].specularColor * specularFactor;
#ifdef SEPARATE_SPECULAR_TEXTURE
        specularContribution *= specularColor;
#endif
#ifdef MATERIAL_PARAMETERS // In MTL: Always present
        specularContribution *= parameters.specularColor;
#endif
        color += specularContribution;
#endif
    }
    
#ifdef LIGHTMAP
    color *= texture(lightmapTexture, lightmapTextureCoord);
#endif
    
#ifdef REFLECTION
    // Apply reflection
    vec3 reflectionDir = normalize(reflect(cameraDirection, normalWorld));
    
    // Reflection dir now points at a sphere. We ignore the z component to get a circle. But we still have to scale it to get to the square XNAlara demands.
    float tanAlpha = reflectionDir.x/reflectionDir.y;
    float cotAlpha = reflectionDir.y/reflectionDir.x;
    float scaleFactor = sqrt(min(1, tanAlpha*tanAlpha) + min(1, cotAlpha*cotAlpha));
    vec2 reflectionTexCoord = scaleFactor * reflectionDir.xy;
    vec4 reflectionColor = texture(reflectionTexture, reflectionTexCoord * 0.5 + 0.5);
    
    color = mix(color, reflectionColor, parameters.reflectionAmount);
#endif
    
#ifdef EMISSION
    // Emission texture
    vec4 emission = texture(emissionTexture, emissionTextureCoord);
    color += emission;
#endif
    
#ifdef USE_ALPHA_TEST
    float alpha = diffuseTexColor.a;
#else
    float alpha = 1.0;
#endif
    screenColor = vec4(color.rgb, alpha);
}
