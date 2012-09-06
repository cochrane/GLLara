/*
 * The actual simplest pixel shader; sorry that I said that about Diffuse. Gets the texture and that's it.
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
	screenColor = texture(diffuseTexture, outTexCoord);
}