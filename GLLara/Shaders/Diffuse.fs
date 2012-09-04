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
	vec3 direction;
	float intensity;
	float shadowDepth;
};

layout(std140) uniform LightData {
	vec3 cameraPosition;
	Light lights[3];
} lightData;

void main()
{
	vec4 diffuseColor = texture(diffuseTexture, outTexCoord) * outColor;
	vec4 lightColor = vec4(0);
	for (int i = 0; i < 3; i++)
	{
		float factor = clamp(dot(normalWorld, -lightData.lights[i].direction), 0, 1);
		float shading = mix(1, factor, lightData.lights[i].shadowDepth);
		lightColor += lightData.lights[i].color * shading;
	}
	
	screenColor = diffuseColor * lightColor;
}