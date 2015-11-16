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

#define GLL_DRAW_STATE_MAX_ACTIVE_TEXTURES 10

/*!
 * @abstract Stores the current rendering state.
 * @discussion Everything that draws has to update this. It can use these
 * fields to avoid state changes.
 */
typedef struct __GLLDrawState {
	GLuint activeProgram;
	int16_t cullFaceMode;
    GLuint activeTexture[GLL_DRAW_STATE_MAX_ACTIVE_TEXTURES];
} GLLDrawState;

#endif
