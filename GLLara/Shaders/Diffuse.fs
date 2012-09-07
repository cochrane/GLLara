/*
 * The simplest pixel shader; gets a color from a single texture, does a standard diffuse calculation for all three lights, returns them.
 */
#version 150

in vec4 outColor;
in vec2 outTexCoord;
in vec3 normalWorld;

out vec4 screenColor;

uniform sampler2D diffuseTexture;

struct Light {
	vec4 color;
	vec4 direction;
	float intensity;
	float shadowDepth;
};

layout(std140) uniform LightData {
	vec4 cameraPosition;
	Light lights[3];
} lightData;

layout(std140) uniform AlphaTest {
	uint mode; // 0 - none, 1 - pass if greater than, 2 - pass if less than.
	float reference;
} alphaTest;

void main()
{
	vec4 diffuseTexColor = texture(diffuseTexture, outTexCoord);
	vec4 diffuseColor = diffuseTexColor * outColor;
	if ((alphaTest.mode == 1U && diffuseTexColor.a <= alphaTest.reference) || (alphaTest.mode == 2U && diffuseTexColor.a >= alphaTest.reference))
		discard;
	
	vec4 lightColor = vec4(0);
	for (int i = 0; i < 3; i++)
	{
		float factor = clamp(dot(normalWorld, -lightData.lights[i].direction.xyz), 0, 1);
		lightColor += lightData.lights[i].color * factor;
	}
	
	screenColor = vec4(diffuseColor.rgb * lightColor.rgb, diffuseTexColor.a);
}