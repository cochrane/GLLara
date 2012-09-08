/*
 * Same as DiffuseBump, except for the lightmap, which is multiplied into the color at every step. Come to think of it, I could multiply it at the end, too, but either way, I'm not 100% certain why this texture exists.
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
uniform sampler2D specularTexture;

uniform vec3 cameraPosition;

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
	vec4 lightmapColor = texture(lightmapTexture, outTexCoord);
	vec4 specularColor = texture(specularTexture, outTexCoord);
	
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
		
		// Add specular color to the color
		// Include lightmap color, too.
		vec4 lightenedColor = diffuseColor + specularColor * specularShading * lightData.lights[i].intensity;
		color += lightData.lights[i].color * diffuseFactor * lightenedColor * lightmapColor;
	}
	
	color.a = diffuseTexColor.a;
	
	screenColor = color;
}
