/*
 * The simplest pixel shader; gets a color from a single texture, does a standard diffuse calculation for all three lights, returns them.
 */

in vec4 outColor;
in vec2 outTexCoord;
in vec3 normalWorld;

out vec4 screenColor;

uniform sampler2D diffuseTexture;

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

#ifdef USE_ALPHA_TEST
layout(std140) uniform AlphaTest {
	uint mode; // 0 - none, 1 - pass if greater than, 2 - pass if less than.
	float reference;
} alphaTest;
#endif

void main()
{
	// Find diffuse texture and do alpha test.
	vec4 diffuseTexColor = texture(diffuseTexture, outTexCoord);
    
#ifdef USE_ALPHA_TEST
	if ((alphaTest.mode == 1U && diffuseTexColor.a <= alphaTest.reference) || (alphaTest.mode == 2U && diffuseTexColor.a >= alphaTest.reference))
		discard;
#endif
	
	// Base diffuse color
	vec4 diffuseColor = diffuseTexColor * outColor;
	
	vec4 color = lightData.ambientColor * diffuseColor;
	for (int i = 0; i < 3; i++)
	{
		// Diffuse term; this version does not use specular
		color += diffuseTexColor * lightData.lights[i].diffuseColor * max(dot(-normalWorld, lightData.lights[i].direction.xyz), 0);
	}
	
#ifdef USE_ALPHA_TEST
    float alpha = diffuseTexColor.a;
#else
    float alpha = 1.0;
#endif
	screenColor = vec4(color.rgb, alpha);
}
