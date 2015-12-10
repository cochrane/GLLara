/*
 *  simd_project.c
 *  LandscapeCreator
 *
 *  Created by Torsten Kammer on 19.01.10.
 *  Copyright 2010 __MyCompanyName__. All rights reserved.
 *
 */

#include "simd_project.h"

#include "simd_matrix.h"

// Calculate frustum matrix.
// Mapping to redbook:
// n = near, f = far, r = -xmax, l = xmax, t = ymax, b = -ymax
// As a result of that: r-l = -2xmax, t-b = 2ymax, r+l = 0, t+b = 0

mat_float16 simd_frustumMatrix(float angle, float aspect, float near, float far)
{
    float ymax = near * tanf(angle * M_PI / 360.0f);
    float xmax = ymax * aspect;
    
    mat_float16 frustumMatrix = simd_mat_identity();
    
    float *frustumMatrixF = (float *) &frustumMatrix;
    
    frustumMatrixF[0*4+0] = near/xmax;
    frustumMatrixF[1*4+1] = near/ymax;
    
    frustumMatrixF[2*4+2] = -(far + near) / (far - near);
    frustumMatrixF[3*4+2] = -(2.0f * far * near) / (far - near);
    
    frustumMatrixF[2*4+3] = -1.0f;
    frustumMatrixF[3*4+3] = 0.0f;
    
    return frustumMatrix;
}

mat_float16 simd_inverseFrustumMatrix(float angle, float aspect, float near, float far)
{
    float ymax = near * tanf(angle * M_PI / 360.0f);
    float xmax = ymax * aspect;
    
    mat_float16 inverseFrustumMatrix = simd_mat_identity();
    
    float *inverseFrustumMatrixF = (float *) &inverseFrustumMatrix;
    
    inverseFrustumMatrixF[0*4+0] = xmax / near;
    inverseFrustumMatrixF[1*4+1] = ymax / near;
    inverseFrustumMatrixF[0*4+1] = 0.0f;
    inverseFrustumMatrixF[1*4+0] = 0.0f;
    
    inverseFrustumMatrixF[2*4+2] = 0.0f;
    inverseFrustumMatrixF[2*4+3] = -(far - near) / (2.0f * near * far);
    inverseFrustumMatrixF[3*4+3] = (far + near) / (2.0f * near * far);
    inverseFrustumMatrixF[3*4+2] = -1.0f;
    
    return inverseFrustumMatrix;
}

mat_float16 simd_orthoMatrix(float left, float right, float bottom, float top, float near, float far)
{
    mat_float16 result = simd_mat_identity();
    
    float *resultF = (float *) &result;
    
    resultF[0*4+0] = 2.0f / (right - left);
    resultF[1*4+1] = 2.0f / (top - bottom);
    resultF[2*4+2] = -2.0f / (far - near);
    
    resultF[3*4+0] = -(right + left)/(right - left);
    resultF[3*4+1] = -(top + bottom)/(top - bottom);
    resultF[3*4+2] = -(far + near)/(far - near);
    
    return result;
}
mat_float16 simd_inverseOrthoMatrix(float left, float right, float bottom, float top, float near, float far)
{
    mat_float16 result = simd_mat_identity();
    
    float *resultF = (float *) &result;
    
    resultF[0*4+0] = 0.5f * (right - left);
    resultF[1*4+1] = 0.5f * (top - bottom);
    resultF[2*4+2] = -0.5f * (far - near);
    
    resultF[3*4+0] = 0.5f * (right + left);
    resultF[3*4+1] = 0.5f * (top + bottom);
    resultF[3*4+2] = 0.5f * (far + near);
    
    return result;
}
