/*
 * Simple vertex shader that transforms the vertex and normal, taking into account the bone weights.
 */
#version 150

uniform mat4 modelViewProjection;
uniform mat4 model;
uniform mat4 boneMatrices[59];

in vec3 position;
in vec3 normal;
in vec4 color;
in vec2 texCoord;
in vec4 tangent;
in uint4 boneIndices;
in vec4 boneWeights;

out vec4 outColor;
out vec2 outTexCoord;
out vec3 normalWorld;

mat4 boneTransform()
{
	mat4 boneTransform = 0;
	boneTransform += boneMatrices[boneIndices[0]] * boneWeights[0];
	boneTransform += boneMatrices[boneIndices[1]] * boneWeights[1];
	boneTransform += boneMatrices[boneIndices[2]] * boneWeights[2];
	boneTransform += boneMatrices[boneIndices[3]] * boneWeights[3];
	return boneTransform;
}

void main()
{
	// Transform
	mat4 bone = boneTransform();
	gl_Position = modelViewProjection * (bone * vec4(position, 1.0));
	normalWorld = mat3(model) * (mat3(bone) * normal);
	
	// Pass through
	outColor = color;
	outTexCoord = texCoord;
}
