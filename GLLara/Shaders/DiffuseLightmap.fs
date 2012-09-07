/*
 * Diffuse and Lightmap. Same as Diffuse, really, except the final color is also multiplied with a lightmap value. Why this has to happen is beyond me; anyone can see that the lightmap could have just as easily been multiplied into the diffuse texture. Maybe it's for HDR rendering.
 */
#version 150

in vec4 outColor;
in vec2 outTexCoord;
in vec3 normalWorld;

out vec4 screenColor;

uniform sampler2D diffuseTexture;
uniform sampler2D lightmapTexture;

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

	vec4 lightmapColor = texture(lightmapTexture, outTexCoord);
	vec4 lightColor = vec4(0);
	for (int i = 0; i < 3; i++)
	{
		float factor = clamp(dot(normalWorld, -lightData.lights[i].direction), 0, 1);
		lightColor += lightData.lights[i].color * factor;
	}
	
	screenColor = vec4(diffuseColor.rgb * lightColor.rgb * lightmapColor.rgb, diffuseTexColor.a);
}