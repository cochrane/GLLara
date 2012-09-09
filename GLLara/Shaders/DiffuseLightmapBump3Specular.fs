/*
 * This is essentially identical to DiffuseLightmapBump3, but the specular color is not always white; instead it is read from its own texture.
 */
#version 150

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

layout(std140) uniform AlphaTest {
	uint mode; // 0 - none, 1 - pass if greater than, 2 - pass if less than.
	float reference;
} alphaTest;

void main()
{
	// Find diffuse texture and do alpha test.
	vec4 diffuseTexColor = texture(diffuseTexture, outTexCoord);
	if ((alphaTest.mode == 1U && diffuseTexColor.a <= alphaTest.reference) || (alphaTest.mode == 2U && diffuseTexColor.a >= alphaTest.reference))
		discard;
	
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
	for (int i = 0; i < 3; i++)
	{
		// Diffuse term
		float diffuseFactor = clamp(dot(-normal, lightData.lights[i].direction.xyz), 0, 1);
		color += diffuseTexColor * lightData.lights[i].diffuseColor * diffuseFactor;
		
		// Specular term
		vec3 reflectedLightDirection = reflect(lightData.lights[i].direction.xyz, normal);
		float specularFactor = pow(clamp(dot(cameraDirection, reflectedLightDirection), 0, 1), parameters.bumpSpecularGloss) * parameters.bumpSpecularAmount;
		color += specularColor * lightData.lights[i].specularColor * specularFactor;
	}
	
	// Lightmap
	color *= texture(lightmapTexture, outTexCoord);
	
	screenColor = vec4(color.rgb, diffuseTexColor.a);
}
