/*
 * Same as DiffuseBump, except for the lightmap, which is multiplied into the color at every step. Come to think of it, I could multiply it at the end, too, but either way, I'm not 100% certain why this texture exists.
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

uniform vec3 cameraPosition;

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
} parameters;

layout(std140) uniform AlphaTest {
	uint mode; // 0 - none, 1 - pass if greater than, 2 - pass if less than.
	float reference;
} alphaTest;

void main()
{
//	// Find diffuse texture and do alpha test.
//	vec4 diffuseTexColor = texture(diffuseTexture, outTexCoord);
//	if ((alphaTest.mode == 1U && diffuseTexColor.a <= alphaTest.reference) || (alphaTest.mode == 2U && diffuseTexColor.a >= alphaTest.reference))
//		discard;
//	
//	// Base diffuse color
//	vec4 diffuseColor = diffuseTexColor * outColor;
//	
//	// Calculate normal
//	vec4 normalMap = texture(bumpTexture, outTexCoord);
//	vec3 normalFromMap = normalMap.rgb * 2 - 1;
//	vec3 normal = normalize(tangentToWorld * normalFromMap);
//	
//	// Direction to camera
//	vec3 cameraDirection = normalize(lightData.cameraPosition.xyz - positionWorld);
//	
//	vec4 color = lightData.ambientColor * diffuseColor;
//	for (int i = 0; i < 3; i++)
//	{
//		// Diffuse term
//		float diffuseFactor = max(dot(-normal, lightData.lights[i].direction.xyz), 0);
//		color += diffuseTexColor * lightData.lights[i].diffuseColor * diffuseFactor;
//		
//		// Specular term
//		vec3 reflectedLightDirection = reflect(lightData.lights[i].direction.xyz, normal);
//		float specularFactor = pow(max(dot(cameraDirection, reflectedLightDirection), 0), parameters.bumpSpecularGloss) * parameters.bumpSpecularAmount;
//		color += lightData.lights[i].specularColor * specularFactor;
//	}
//	
//	// Lightmap
//	color *= texture(lightmapTexture, outTexCoord);
//
//	screenColor = vec4(color.rgb, diffuseTexColor.a);
	screenColor = texture(diffuseTexture, outTexCoord);
}
