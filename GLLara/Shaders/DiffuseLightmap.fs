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

layout(std140) uniform Light {
	vec4 color;
	vec3 direction;
	float intensity;
	float shadowDepth;
} lights[3];

void main()
{
	vec4 diffuseColor = texture(diffuseColor, outTexCoord) * outColor;
	vec4 lightmapColor = texture(lightmapTexture, outTexCoord);
	vec4 lightColor = vec4(0);
	for (int i = 0; i < 3; i++)
	{
		float factor = clamp(dot(normal, -lights[i].direction), 0, 1);
		float shading = mix(1, factor, lights[i].shadowDepth);
		lightColor += lights[i].color * shading;
	}
	
	screenColor = diffuseColor * lightmapColor * lightColor;
}