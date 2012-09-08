/*
 * Basically the same thing as Bump.vs, but without the bone weights. It uses boneMatrices[0] as the model matrix.
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
out vec3 positionWorld;
out mat3 tangentToWorld;

void main()
{
	// Transformation
	gl_Position = transform.viewProjection * (boneMatrices[0] * vec4(position, 1.0));
	
	// Relative to world
	positionWorld = vec3(boneMatrices[0] * vec4(position, 1.0));
	normalWorld = vec3(boneMatrices[0] * vec4(normal, 0.0));
	
	// Tangents
	vec3 tangentU = normalize(tangent.xyz);
	vec3 tangentV = normalize(cross(normal, tangentU) * tangent.w);
	vec3 normal = normalize(normal);
	
	tangentToWorld = mat3(boneMatrices[0]) * mat3(tangentU, tangentV, normal);
	
	// Pass through
	outColor = color;
	outTexCoord = texCoord;
}
