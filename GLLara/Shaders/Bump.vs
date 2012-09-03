/*
 * More complicated vertex shader, also using bone weights. The main difference is that it outputs the tangents matrix, and also a position in global model space. I'm not entirely sure that the normal is needed here; but getting rid of that and having per-pixel diffuse lighting has to wait for another day.
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
in uint4 boneIndices;
in vec4 boneWeights;

out vec4 outColor;
out vec2 outTexCoord;
out vec3 normalWorld;
out vec3 positionWorld;
out mat3 tangentToWorld;

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
	// Transformation
	mat4 bone = boneTransform();
	gl_Position = transform.modelViewProjection * (bone * vec4(position, 1.0));
	
	// Relative to world
	mat4 worldBone = transform.model * bone;
	positionWorld = vec3(worldBone * vec4(position, 1.0));
	normalWorld = vec3(worldBone * vec4(normal, 0.0));
	
	// Tangents
	vec3 tangentU = normalize(tangent.xyz);
	vec3 tangentV = normalize(cross(normal, tangentU) * tangent.w);
	vec3 normal = normalize(normal);
	
	tangentToWorld = mat3(worldBone) * transpose(mat3(tangentU, tangentV, normal));

	// Pass through
	outColor = color;
	outTexCoord = texCoord;
}
