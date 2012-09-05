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

void main()
{
	vec4 diffuseColor = texture(diffuseTexture, outTexCoord) * outColor;
	vec4 lightColor = vec4(0);
	for (int i = 0; i < 3; i++)
	{
		float factor = clamp(dot(normalWorld, -lightData.lights[i].direction.xyz), 0, 1);
		lightColor += lightData.lights[i].color * factor;
	}
	
	screenColor = diffuseColor * lightColor;
}