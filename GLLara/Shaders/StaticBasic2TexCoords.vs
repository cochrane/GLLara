/*
 * Like StaticBasic, but passing through two texture coordinates.
 */
#version 150

layout(std140) uniform Transform {
	mat4 viewProjection;
} transform;

layout(std140) uniform Bones {
	mat4 transforms[512];
} bones;

in vec3 position;
in vec3 normal;
in vec4 color;
in vec2 texCoord;
in vec4 tangent;
in vec2 texCoord2;
in vec4 tangent2;
in ivec4 boneIndices;
in vec4 boneWeights;

out vec4 outColor;
out vec2 outTexCoord;
out vec2 outTexCoord2;
out vec3 normalWorld;

void main()
{
	// Transform
	gl_Position = transform.viewProjection * bones.transforms[0] * vec4(position, 1.0);
	normalWorld = mat3(bones.transforms[0]) * normal;
	
	// Pass through
	outColor = color;
	outTexCoord = texCoord;
	outTexCoord2 = texCoord2;
}
