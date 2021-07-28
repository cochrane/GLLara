/*
 * Combined shader that does everything based on what is defined when compiling.
 *
 * Defines:
 * - CALCULATE_NORMAL_TO_WORLD: Calculates normal to world vector
 * - CALCULATE_TANGENT_TO_WORLD: Calculates tangentToWorld matrix
 * - USE_SKINNING: Calculates bone transformation based on skinning information; else just uses first bone matrix.
 * - SECOND_TEX_COORD: Passes through an additional set of tangent and texture coordinate. TODO: The second tangent is ignored. Could probably just get rid of it.
 */

layout(std140) uniform Transform {
    mat4 viewProjection;
} transform;

layout(std140) uniform Bones {
    mat4 normalPermute;
    mat4 transforms[512];
} bones;

in vec3 position;
in vec3 normal;
in vec4 color;
$$in vec2 texCoord%ld;
in vec4 tangent;
#ifdef SECOND_TEX_COORD
in vec2 tangent2;
#endif
in ivec4 boneIndices;
in vec4 boneWeights;

out vec4 outColor;
##out vec2 outTexCoord%ld;
out vec3 positionWorld;
#ifdef CALCULATE_NORMAL_WORLD
out vec3 normalWorld;
#endif
#ifdef CALCULATE_TANGENT_TO_WORLD
out mat3 tangentToWorld;
#endif

mat4 boneTransform()
{
#ifdef USE_SKINNING
    return bones.transforms[boneIndices[0]] * boneWeights[0] +
    bones.transforms[boneIndices[1]] * boneWeights[1] +
    bones.transforms[boneIndices[2]] * boneWeights[2] +
    bones.transforms[boneIndices[3]] * boneWeights[3];
#else
    return bones.transforms[0];
#endif
}

void main()
{
    // Transformation
    mat4 bone = boneTransform();
    gl_Position = transform.viewProjection * (bone * vec4(position, 1.0));
    
    // Relative to world
    positionWorld = vec3(bone * vec4(position, 1.0));
    
#ifdef CALCULATE_NORMAL_WORLD
    // Normal
    normalWorld = mat3(bone) * normal;
#endif
    
#ifdef CALCULATE_TANGENT_TO_WORLD
    // Tangents
    vec3 tangentU = normalize(tangent.xyz);
    vec3 tangentV = normalize(cross(normal, tangentU) * sign(tangent.w));
    vec3 normal = normalize(normal);
    
    // TODO Should this be 'bone' instead of 'bones.transforms[0]'?
    tangentToWorld = mat3(bones.transforms[0]) * mat3(tangentU, tangentV, normal) * mat3(bones.normalPermute);
#endif
    
    // Pass through
    outColor = color;
$$  outTexCoord%ld = texCoord%ld;
}
