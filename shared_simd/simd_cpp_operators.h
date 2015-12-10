#pragma once
/*
 *  simd_cpp_operators.h
 *  Hubschrauber
 *
 *  Created by Torsten Kammer on 03.07.09.
 *  Copyright 2009 __MyCompanyName__. All rights reserved.
 *
 */

#include "simd_functions.h"
#include "simd_matrix.h"
#include "simd_quaternion.h"

#pragma mark Vector

#pragma mark Matrix

inline mat_float16 operator*(const mat_float16 a, const mat_float16 b)
{
    return simd_mat_mul(a, b);
}

inline vec_float4 operator*(const mat_float16 a, const vec_float4 b)
{
    return simd_mat_vecmul(a, b);
}
