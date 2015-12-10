/*
 *  simd_quaternion.h
 *  Hubschrauber
 *
 *  Created by Torsten Kammer on 03.07.09.
 *  Copyright 2009 __MyCompanyName__. All rights reserved.
 *
 */

#pragma once

#include "simd_functions.h"
#include "simd_matrix.h"

#include <math.h>
#include <string.h>

static inline vec_float4 simd_quat_from_mat(const mat_float16 mat)
{
    // Lazy, all in scalar code. Not nice, I know, but it (ought to) works.
    
    float matrix[4][4];
    memcpy(matrix, &mat, sizeof(mat_float16));
    
    float x, y, z, w;
    
    float T = 1 + matrix[0][0] + matrix[1][1] + matrix[2][2];
    
    float S;
    if (fabsf(T) > 0.0000001f)
    {
        S = sqrtf(T) * 2.0f;
        x = (matrix[2][1] - matrix[1][2]) / S;
        y = (matrix[0][2] - matrix[2][0]) / S;
        z = (matrix[1][0] - matrix[0][1]) / S;
        w = 0.25f * S;
    }
    else
    {
        if (matrix[0][0] > matrix[1][1] && matrix[0][0] > matrix[2][2])
        {	// Column 0:
            S  = sqrtf( 1.0f + matrix[0][0] - matrix[1][1] - matrix[2][2] ) * 2.0f;
            x = 0.25f * S;
            y = (matrix[0][1] + matrix[1][0] ) / S;
            z = (matrix[2][0] + matrix[0][2] ) / S;
            w = (matrix[1][2] - matrix[2][1] ) / S;
        }
        else if ( matrix[1][1] > matrix[2][2] )
        {	// Column 1:
            S  = sqrtf( 1.0f + matrix[1][1] - matrix[0][0] - matrix[2][2] ) * 2.0f;
            x = (matrix[0][1] + matrix[1][0] ) / S;
            y = 0.25f * S;
            z = (matrix[1][2] + matrix[2][1] ) / S;
            w = (matrix[2][0] - matrix[0][2] ) / S;
        }
        else
        {	// Column 2:
            S  = sqrtf( 1.0f + matrix[2][2] - matrix[0][0] - matrix[1][1] ) * 2.0f;
            x = (matrix[2][0] + matrix[0][2] ) / S;
            y = (matrix[1][2] + matrix[2][1] ) / S;
            z = 0.25f * S;
            w = (matrix[0][1] - matrix[1][0] ) / S;
        }
    }
    
    return simd_make(x, y, z, w);
}

static inline mat_float16 simd_quat_to_mat(const vec_float4 quat)
{
    float matrix[4][4];
    
    const float *q = (const float *) &quat;
    
    float xx = q[0] * q[0];
    float xy = q[0] * q[1];
    float xz = q[0] * q[2];
    float xw = q[0] * q[3];
    float yy = q[1] * q[1];
    float yz = q[1] * q[2];
    float yw = q[1] * q[3];
    float zz = q[2] * q[2];
    float zw = q[2] * q[3];
    
    matrix[0][0] = 1.f - 2.f * (yy + zz);
    matrix[0][1] = 2.f * (xy - zw);
    matrix[0][2] = 2.f * (xz + yw);
    matrix[0][3] = 0.0f;
    matrix[1][0] = 2.f * (xy + zw);
    matrix[1][1] = 1.f - 2.f * (xx + zz);
    matrix[1][2] = 2.f * (yz - xw);
    matrix[1][3] = 0.0f;
    matrix[2][0] = 2.f * (xz - yw);
    matrix[2][1] = 2.f * (yz + xw);
    matrix[2][2] = 1.f - 2.f * (xx + yy);
    matrix[2][3] = 0.0f;
    
    mat_float16 result;
    memcpy(&result, matrix, sizeof(mat_float16));
    
    return result;
}
