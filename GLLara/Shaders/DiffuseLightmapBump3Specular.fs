/*
 * This is essentially identical to DiffuseLightmapBump3, but the specular color is not always white; instead it is read from its own texture.
 */

in vec4 outColor;
in vec2 outTexCoord;
in vec3 positionWorld;
in mat3 tangentToWorld;

out vec4 screenColor;

uniform sampler2D diffuseTexture;
uniform sampler2D lightmapTexture;
uniform sampler2D bumpTexture;
uniform sampler2D bump1Texture;
uniform sampler2D bump2Texture;
uniform sampler2D maskTexture;

uniform sampler2D specularTexture;

struct Light {
	vec4 diffuseColor;
	vec4 specularColor;
	vec4 direction;
};

layout(std140) uniform LightData {
	vec4 cameraPosition;
	vec4 ambientColor;
	Light lights[3];
} lightData;

uniform RenderParameters {
	float bumpSpecularGloss;
	float bumpSpecularAmount;
	float bump1UVScale;
	float bump2UVScale;
} parameters;

#ifdef USE_ALPHA_TEST
layout(std140) uniform AlphaTest {
    uint mode; // 0 - none, 1 - pass if greater than, 2 - pass if less than.
    float reference;
} alphaTest;
#endif

void main()
{
	// Find diffuse texture and do alpha test.
    vec4 diffuseTexColor = texture(diffuseTexture, outTexCoord);
    
#ifdef USE_ALPHA_TEST
    if ((alphaTest.mode == 1U && diffuseTexColor.a <= alphaTest.reference) || (alphaTest.mode == 2U && diffuseTexColor.a >= alphaTest.reference))
        discard;
#endif
	
	// Separate specular color
	vec4 specularColor = texture(specularTexture, outTexCoord);
	
	// Base diffuse color
	vec4 diffuseColor = diffuseTexColor * outColor;
	
	// Calculate normal
	vec4 normalMap = texture(bumpTexture, outTexCoord);
	vec4 detailNormalMap1 = texture(bump1Texture, outTexCoord * parameters.bump1UVScale);
	vec4 detailNormalMap2 = texture(bump2Texture, outTexCoord * parameters.bump2UVScale);
	vec4 maskColor = texture(maskTexture, outTexCoord);
	
	vec3 normalFromMap = (normalMap.rgb + detailNormalMap1.rgb * maskColor.r + detailNormalMap2.rgb * maskColor.g) * 2 - 1;
	vec3 normal = normalize(tangentToWorld * normalFromMap);
	
	// Direction to camera
	vec3 cameraDirection = normalize(lightData.cameraPosition.xyz - positionWorld);
	
	vec4 color = lightData.ambientColor * diffuseColor;
	for (int i = 0; i < 1/*3*/; i++)
	{
		// Diffuse term
		float diffuseFactor = max(dot(-normal, lightData.lights[i].direction.xyz), 0);
		color += diffuseTexColor * lightData.lights[i].diffuseColor * diffuseFactor;
		
		// Specular term
		vec3 reflectedLightDirection = reflect(lightData.lights[i].direction.xyz, normal);
		float specularFactor = pow(max(dot(cameraDirection, reflectedLightDirection), 0), parameters.bumpSpecularGloss) * parameters.bumpSpecularAmount;
		if (diffuseFactor <= 0.001) specularFactor = 0;
		color += specularColor * lightData.lights[i].specularColor * specularFactor;
	}
	
	// Lightmap
	color *= texture(lightmapTexture, outTexCoord);
	
#ifdef USE_ALPHA_TEST
    float alpha = diffuseTexColor.a;
#else
    float alpha = 1.0;
#endif
	screenColor = vec4(color.rgb, alpha);
}
