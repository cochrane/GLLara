/*
 * Like Basic, but not using bone weights (the first bone matrix is used as the model matrix)
 */
#version 150

layout(std140) uniform Transform {
	mat4 viewProjection;
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

void main()
{
	// Transform
	gl_Position = transform.viewProjection * boneMatrices[0] * vec4(position, 1.0);
	normalWorld = mat3(boneMatrices[0]) * normal;
	
	// Pass through
	outColor = color;
	outTexCoord = texCoord;
}
