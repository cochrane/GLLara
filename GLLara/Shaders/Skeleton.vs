//
//  Skeleton.vs
//  GLLara
//
//  Created by Torsten Kammer on 25.09.12.
//  Copyright (c) 2012 Torsten Kammer. All rights reserved.
//

#version 150

layout(std140) uniform Transform {
	mat4 viewProjection;
} transform;

in vec3 position;
in vec4 color;

out vec4 outColor;

void main()
{
	gl_Position = transform.viewProjection * vec4(position, 1.0);
	outColor = color;
}
