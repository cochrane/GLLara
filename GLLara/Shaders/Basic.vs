/*
 * Simple vertex shader that transforms the vertex and normal, taking into account the bone weights.
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
in ivec4 boneIndices;
in vec4 boneWeights;

out vec4 outColor;
out vec2 outTexCoord;
out vec3 normalWorld;

mat4 boneTransform()
{
	return bones.transforms[boneIndices[0]] * boneWeights[0] +
		bones.transforms[boneIndices[1]] * boneWeights[1] +
		bones.transforms[boneIndices[2]] * boneWeights[2] +
		bones.transforms[boneIndices[3]] * boneWeights[3];
}

void main()
{
	// Transform
	mat4 bone = boneTransform();
	gl_Position = transform.viewProjection * bone * vec4(position, 1.0);
	normalWorld = mat3(bone) * normal;
	
	// Pass through
	outColor = color;
	outTexCoord = texCoord;
}
