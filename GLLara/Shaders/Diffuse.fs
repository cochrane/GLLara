/*
 * The simplest pixel shader; gets a color from a single texture, does a standard diffuse calculation for all three lights, returns them.
 */
#version 150

in vec4 outColor;
in vec2 outTexCoord;
in vec3 normalWorld;

out vec4 screenColor;

uniform sampler2D diffuseTexture;

layout(std140) uniform Light {
	vec4 color;
	vec3 direction;
	float intensity;
	float shadowDepth;
} lights[3];

void main()
{
	vec4 diffuseColor = texture(diffuseColor, outTexCoord) * outColor;
	vec4 lightColor = vec4(0);
	for (int i = 0; i < 3; i++)
	{
		float factor = clamp(dot(normal, -lights[i].direction), 0, 1);
		float shading = mix(1, factor, lights[i].shadowDepth);
		lightColor += lights[i].color * shading;
	}
	
	screenColor = diffuseColor * lightColor;
}