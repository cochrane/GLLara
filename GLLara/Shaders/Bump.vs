/*
 * More complicated vertex shader, also using bone weights. The main difference is that it outputs the tangents matrix, and also a position in global model space. I'm not entirely sure that the normal is needed here; but getting rid of that and having per-pixel diffuse lighting has to wait for another day.
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
out vec3 positionWorld;
out mat3 tangentToWorld;

mat4 boneTransform()
{
	return boneMatrices[boneIndices[0]] * boneWeights[0] +
		boneMatrices[boneIndices[1]] * boneWeights[1] +
		boneMatrices[boneIndices[2]] * boneWeights[2] +
		boneMatrices[boneIndices[3]] * boneWeights[3];
}

void main()
{
	// Transformation
	mat4 bone = boneTransform();
	gl_Position = transform.viewProjection * (bone * vec4(position, 1.0));
	
	// Relative to world
	positionWorld = vec3(bone * vec4(position, 1.0));
	
	// Tangents
	vec3 tangentU = normalize(tangent.xyz);
	vec3 tangentV = normalize(cross(normal, tangentU) * tangent.w);
	vec3 normal = normalize(normal);
	
	tangentToWorld = mat3(bone) * mat3(tangentU, tangentV, normal);

	// Pass through
	outColor = color;
	outTexCoord = texCoord;
}
