//
//  GLLDrawState.h
//  GLLara
//
//  Created by Torsten Kammer on 27.01.13.
//  Copyright (c) 2013 Torsten Kammer. All rights reserved.
//

#ifndef GLLara_GLLDrawState_h
#define GLLara_GLLDrawState_h

#include <OpenGL/gltypes.h>

typedef struct __GLLDrawState {
	GLuint activeProgram;
	int16_t cullFaceMode;
} GLLDrawState;

#endif
