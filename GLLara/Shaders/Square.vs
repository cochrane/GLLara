/*
 * Simple shader that draws a textured square
 */

in vec2 position;

out vec2 coord;

void main()
{
	gl_Position = vec4(position, 1, 0);
	coord = position * 0.5 + 0.5;
}