/*
 * Simple shader that draws a textured square
 */
#version 150

uniform sampler2D texImage;

in vec2 coord;

out vec4 color;

void main()
{
	color = texture(texImage, coord);
}
