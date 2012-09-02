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

uniform vec3 cameraPosition;

layout(std140) uniform Light {
	vec4 color;
	vec3 direction;
	float intensity;
	float shadowDepth;
} lights[3];

uniform float bumpSpecularGloss;
uniform float bumpSpecularAmount;

void main()
{
	vec4 diffuseColor = texture(diffuseColor, outTexCoord) * outColor;
	vec4 normalMap = texture(bumpTexture, outTexCoord);
	vec4 lightmapColor = texture(lightmapTexture, outTexCoord);
	
	vec3 normalFromMap = vec3(normalMap.rg * 2 - 1, normalMap.b);
	vec3 normal = normalize(tangentToWorld * normalFromMap);
	
	vec3 cameraDirection = normalize(positionWorld - cameraPosition);
	
	vec4 color = vec4(0);
	for (int i = 0; i < 3; i++)
	{
		// Calculate diffuse factor
		float diffuseFactor = clamp(dot(normal, -lights[i].direction), 0, 1);
		float diffuseShading = mix(1, factor, lights[i].shadowDepth);
		
		// Calculate specular factor
		vec3 refLightDir = -reflect(lights[i].direction, normal);
		float specularFactor = clamp(dot(cameraDirection, refLightDir), 0, 1);
		float specularShading = diffuseFactor * pow(specularFactor, bumpSpecularGloss) * bumpSpecularAmount;
		
		// Make diffuse color brighter by specular amount, then apply normal diffuse shading (that means specular highlights are always white).
		// Include lightmap color, too.
		vec4 lightenedColor = diffuseColor + vec4(vec3(specularShading), 1.0);
		color += lights[i].color * diffuseShading * lightenedColor * lightmapColor;
	}
	
	color.a = diffuseColor.a;
	
	screenColor = color;
}
