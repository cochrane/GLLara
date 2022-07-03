/*
 *  simd_matrix.c
 *  Hubschrauber
 *
 *  Created by Torsten Kammer on 08.07.09.
 *  Copyright 2009 __MyCompanyName__. All rights reserved.
 *
 */

#include "simd_matrix.h"

mat_float16 simd_mat_euler(vec_float4 angles, vec_float4 position)
{
    // TODO: Where on earth does this code come from?
    mat_float16 result;
    
    float *mat = (float *) &result;
    const float *ang = (const float *) &angles;
    
    float sa = sinf(ang[2]);
    float ca = cosf(ang[2]);
    float sb = sinf(ang[0]);
    float cb = cosf(ang[0]);
    float sh = sinf(ang[1]);
    float ch = cosf(ang[1]);
    
    mat[ 0] = ch*ca;
    mat[ 1] = sa;
    mat[ 2] = -sh*ca;
    mat[ 3] = 0.0f;
    
    mat[ 4] = -ch*sa*cb + sh*sb;
    mat[ 5] = ca*cb;
    mat[ 6] = sh*sa*cb + ch*sb;
    mat[ 7] = 0.0f;
    
    mat[ 8] = ch*sa*sb + sh*cb;
    mat[ 9] = -ca*sb;
    mat[10] = -sh*sa*sb + ch*cb;
    mat[11] = 0.0f;
    
    result.columns[3] = position;
    
    return result;
}
