#ifdef HAS_VERTEX_COLOR
in vec4 outColor;
#endif

#ifdef HAS_TEXTURE
in vec2 outTexCoord;
uniform sampler2D baseColorTexture;
#endif

uniform RenderParameters {
    vec4 baseColorFactor;
} parameters;

out vec4 screenColor;

void main() {
    vec4 color = parameters.baseColorFactor;
    
#ifdef HAS_VERTEX_COLOR
    color *= outColor;
#endif
#ifdef HAS_TEXTURE
    color *= texture(baseColorTexture, outTexCoord);
#endif
    
    screenColor = color;
}
