/*
 * Advanced multi-step version of DiffuseLightmapBump. This uses not one, not two, but three bump maps! There is one master bump map. It's result is then modified by the two detail bump maps, which are repeated quite often and essentially include the high-frequency detail information. They seem to be used mostly for cloth pattern and the like.
 *
 * After the more complicated way of getting the bump map normal, it is identical to DiffuseLightmapBump.
 */
#version 150

in vec4 outColor;
in vec2 outTexCoord;
in vec3 normalWorld;
in vec3 positionWorld;
in mat3 tangentToWorld;

out vec4 screenColor;

uniform sampler2D diffuseTexture;
uniform sampler2D lightmapTexture;
uniform sampler2D bumpTexture;
uniform sampler2D bump1Texture;
uniform sampler2D bump2Texture;
uniform sampler2D maskTexture;

struct Light {
	vec4 color;
	vec4 direction;
	float intensity;
	float shadowDepth;
};

layout(std140) uniform LightData {
	vec3 cameraPosition;
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
	vec4 diffuseTexColor = texture(diffuseTexture, outTexCoord);
	if ((alphaTest.mode == 1U && diffuseTexColor.a <= alphaTest.reference) || (alphaTest.mode == 2U && diffuseTexColor.a >= alphaTest.reference))
		discard;
	vec4 diffuseColor = diffuseTexColor * outColor;

	vec4 normalMap = texture(bumpTexture, outTexCoord);
	vec4 detailNormalMap1 = texture(bump1Texture, outTexCoord * parameters.bump1UVScale);
	vec4 detailNormalMap2 = texture(bump2Texture, outTexCoord * parameters.bump2UVScale);
	vec4 maskColor = texture(maskTexture, outTexCoord);
	
	vec4 lightmapColor = texture(lightmapTexture, outTexCoord);
	
	// Combine normal textures
	vec3 normalColor = normalMap.rgb + (detailNormalMap1.rgb - 0.5) * maskColor.r + (detailNormalMap2.rgb - 0.5) * maskColor.g;
	
	// Derive actual normal
	vec3 normalFromMap = vec3(normalMap.rg * 2 - 1, normalMap.b);
	vec3 normal = normalize(tangentToWorld * normalFromMap);
	
	vec3 cameraDirection = normalize(positionWorld - lightData.cameraPosition);
	
	vec4 color = vec4(0);
	for (int i = 0; i < 3; i++)
	{
		// Calculate diffuse factor
		float diffuseFactor = clamp(dot(normal, -lightData.lights[i].direction), 0, 1);
		// Apply the shadow depth that is used instead of ambient lighting
		diffuseFactor = mix(1, diffuseFactor, lightData.lights[i].shadowDepth);
		
		// Calculate specular factor
		vec3 refLightDir = -reflect(lightData.lights[i].direction, normal);
		float specularFactor = clamp(dot(cameraDirection, refLightDir), 0, 1);
		float specularShading = diffuseFactor * pow(specularFactor, parameters.bumpSpecularGloss) * parameters.bumpSpecularAmount;
		
		// Make diffuse color brighter by specular amount, then apply normal diffuse shading (that means specular highlights are always white).
		// Include lightmap color, too.
		vec4 lightenedColor = diffuseColor + vec4(vec3(specularShading), 1.0);
		color += lightData.lights[i].color * diffuseFactor * lightenedColor * lightmapColor;
	}
	
	color.a = diffuseTexColor.a;
	
	screenColor = color;
}
