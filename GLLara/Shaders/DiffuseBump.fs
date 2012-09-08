/*
 * Bump-mapped rendering. This does not support the special weird bump map shadows that XNALara does; I may add them later, once I figured out what they do. (I could add them now, but I do not add code where I don't understand what it does, thank you very much). A fun detail: Apparently only things with bumpmaps get specular highlights, and apparently the diffuse light value is not modified by the bumpmap. Not sure why; it doesn't cost anything extra.
 */
#version 150

in vec4 outColor;
in vec2 outTexCoord;
in vec3 normalWorld;
in vec3 positionWorld;
in mat3 tangentToWorld;

out vec4 screenColor;

uniform sampler2D diffuseTexture;
uniform sampler2D bumpTexture;

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
	
	vec3 normalFromMap = vec3(normalMap.rg * 2 - 1, normalMap.b);
	vec3 normal = normalize(tangentToWorld * normalFromMap);
	
	vec3 cameraDirection = normalize(positionWorld - lightData.cameraPosition);
	
	vec4 color = vec4(0);
	for (int i = 0; i < 3; i++)
	{
		// Calculate diffuse factor
		float diffuseFactor = clamp(dot(normalWorld, -lightData.lights[i].direction.xyz), 0, 1);
		// Apply the shadow depth that is used instead of ambient lighting
		diffuseFactor = mix(1, diffuseFactor, lightData.lights[i].shadowDepth);
		
		// Calculate specular factor
		vec3 refLightDir = -reflect(lightData.lights[i].direction.xyz, normal);
		float specularFactor = clamp(dot(cameraDirection, refLightDir), 0, 1);
		float specularShading = diffuseFactor * pow(specularFactor, parameters.bumpSpecularGloss) * parameters.bumpSpecularAmount;
		
		// Make diffuse color brighter by specular amount, then apply normal diffuse shading (that means specular highlights are always white).
		vec4 lightenedColor = diffuseColor + vec4(vec3(specularShading), 1.0);
		color += lightData.lights[i].color * diffuseFactor * lightenedColor;
	}
	
	color.a = diffuseTexColor.a;
	
	screenColor = color;
}
