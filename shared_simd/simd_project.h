#pragma once
/*
 *  simd_project.h
 *  LandscapeCreator
 *
 *  Created by Torsten Kammer on 19.01.10.
 *  Copyright 2010 __MyCompanyName__. All rights reserved.
 *
 */

#include "simd_types.h"

mat_float16 simd_frustumMatrix(float fovy, float aspect, float near, float far);
mat_float16 simd_inverseFrustumMatrix(float fovy, float aspect, float near, float far);

mat_float16 simd_orthoMatrix(float left, float right, float bottom, float top, float near, float far);
mat_float16 simd_inverseOrthoMatrix(float left, float right, float bottom, float top, float near, float far);
