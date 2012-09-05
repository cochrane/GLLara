/*
 * Simple vertex shader that transforms the vertex and normal, taking into account the bone weights.
 */
#version 150

layout(std140) uniform Transform {
	mat4 modelViewProjection;
	mat4 model;
} transform;

uniform mat4 boneMatrices[59];

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
	return boneMatrices[boneIndices[0]] * boneWeights[0] +
		boneMatrices[boneIndices[1]] * boneWeights[1] +
		boneMatrices[boneIndices[2]] * boneWeights[2] +
		boneMatrices[boneIndices[3]] * boneWeights[3];
}

void main()
{
	// Transform
	mat4 bone = boneTransform();
	gl_Position = transform.modelViewProjection * bone * vec4(position, 1.0);
	normalWorld = mat3(transform.model) * (mat3(bone) * normal);
	
	// Pass through
	outColor = color;
	outTexCoord = texCoord;
}
