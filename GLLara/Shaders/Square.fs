/*
 * Simple shader that draws a textured square
 */

uniform sampler2D texImage;

in vec2 coord;

out vec4 color;

void main()
{
	color = texture(texImage, coord);
}
