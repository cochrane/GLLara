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
    vec_float4 sins = _simd_sin_f4(angles);
    vec_float4 coss = _simd_cos_f4(angles);
    
    mat_float16 result;
    result.columns[0] = simd_make_float4(coss.y*coss.z,
                                         sins.z,
                                         -sins.y*coss.z,
                                         0.0f);
    
    result.columns[1] = simd_make_float4(-coss.y*sins.z*coss.x + sins.y*sins.x,
                                         coss.z*coss.x,
                                         sins.y*sins.z*coss.x + coss.y*sins.x,
                                         0.0f);
    
    result.columns[2] = simd_make_float4(coss.y*sins.z*sins.x + sins.y*coss.x,
                                         -coss.z*sins.x,
                                         -sins.y*sins.z*sins.x + coss.y*coss.x,
                                         0.0f);
    
    result.columns[3] = position;
    
    return result;
}

vec_float4 simd_euler_mat(mat_float16 matrix) {
    float x, y, z;
    
    /* Note that based on the above:
     cos(y)cos(z)      -cos(y)sin(z)cos(x)+sin(y)sin(x)    cos(y)sin(z)sin(x)+sin(y)cos(x)
     sin(z)            cos(z)cos(x)                        -cos(z)sin(x)
     -sin(y)cos(z)     sin(y)sin(z)cos(x)+cos(y)sin(x)     -sin(y)sin(z)sin(x)+cos(y)cos(x)
     
     z = asin(a.c0.r1)
     Identities: tan = sin/cos
     -sin(y)cos(z) / cos(y)cos(z) = a.c0.r2/a.c0.r0 = -tan(y) iff cos(y)cos(z) != 0
     -cos(z)sin(x) / cos(z)cos(x) = a.c2.r1/a.c1.r1 = -tan(x) iff cos(z)cos(x) != 0
     
     See http://eecs.qmul.ac.uk/~gslabaugh/publications/euler.pdf (indices don't quite match because their matrix is laid out differently but the general principle holds)
     */
    
    // TODO Epsilon
    if (fabsf(matrix.columns[0].y) != 1.0f) {
        float sinz = matrix.columns[0].y;
        float cosz = sqrtf(1.0f - sinz);
        z = asinf(sinz);
        
        y = -atan2f(matrix.columns[0].z / cosz, matrix.columns[0].x / cosz);
        x = -atan2f(matrix.columns[2].y / cosz, matrix.columns[1].y / cosz);
    } else {
        // Gimbal locked
        if (matrix.columns[0].y > 0.0f) {
            z = M_PI_2;
            /*
             Thus sin(z) = +1, cos(z) = 0, thus:
             0     -cos(y)cos(x)+sin(y)sin(x)   cos(y)sin(x)+sin(y)cos(x)
             1     0                            0
             0     sin(y)cos(x)+cos(y)sin(x)    -sin(y)sin(x)+cos(y)cos(x)
             
             c1.x = sin(y)sin(x) - cos(y)cos(x) = -cos(y + x)
             c1.z = sin(y)cos(x) + cos(y)sin(x) = sin(y + x)
             */
            
            x = 0.0f; // Assign arbitrarily and because it's easier.
            // => y+x=y, => tan(y)=sin(y)/cos(y) = c1.z/-c1.x
            y = atan2f(matrix.columns[1].z, -matrix.columns[1].x);
            
        } else {
            z = -M_PI_2;
            /*
             Thus sin(z) = -1, cos(z) = 0, thus:
             0     +cos(y)cos(x)+sin(y)sin(x)   -cos(y)sin(x)+sin(y)cos(x)
             -1    0                            0
             0     -sin(y)cos(x)+cos(y)sin(x)    +sin(y)sin(x)+cos(y)cos(x)
             
             c1.x = cos(x)cos(y) + sin(x)sin(y) = cos(x-y) = cos(y-x)
             c1.z = sin(x)cos(y) - cos(x)sin(y) = sin(x-y)
             c2.x = sin(y)cos(x) - cos(y)sin(x) = sin(y-x)
             */
            
            x = 0.0f;// Assign arbitrarily and because it's easier.
            // => y-x=y, => tan(y)=sin(y)/cos(y) = c2.x/c1.x
            y = atan2f(matrix.columns[2].x, matrix.columns[1].x);
        }
        
    }
    
    return simd_make_float4(x, y, z, 0.0);
}
