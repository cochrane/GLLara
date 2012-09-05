#pragma once
/*
 *  simd_types.h
 *  LandscapeCreator
 *
 *  Created by Torsten Kammer on 04.09.09.
 *  Copyright 2009 __MyCompanyName__. All rights reserved.
 *
 */

#include <math.h>
#include <stdlib.h>

/*!
 * @abstract Datentyp für Vektor
 * @discussion Der Standard-Datentyp für SIMD speichert vier floats. Der Name
 * ist gleich dem Standard-Namen, den IBM fuer den Cell (sowohl PPU als auch
 * SPU) verwendet.
 */
#if defined(__SSE__)
#include <xmmintrin.h>
typedef float vec_float4 __attribute__ ((__vector_size__ (16)));
typedef unsigned int vec_uint4 __attribute__ ((__vector_size__ (16)));
typedef unsigned short vec_ushort8 __attribute__ ((__vector_size__ (16)));
typedef unsigned char vec_uchar16 __attribute__ ((__vector_size__ (16)));
#elif defined(__VEC__) || defined(__PPU__)
#define SIMD_HAS_PERM 1
#if !defined(__APPLE_ALTIVEC__)
#include <altivec.h>
#endif /* __APPLE_ALTIVEC__ */
#if !defined(__VEC__)
#define __VEC__
#endif
#ifdef __APPLE_CC__
typedef __vector float vec_float4;
typedef __vector unsigned int vec_uint4;
typedef __vector unsigned short vec_ushort8;
typedef __vector unsigned char vec_uchar16;
#else /* Nicht Mac */
#include <vec_types.h>
#endif /* __APPLE_CC__ */
#elif defined(__SPU__)
#define SIMD_HAS_PERM 1
#include <spu_intrinsics.h>
#elif defined(_ARM_ARCH_7)
#define __NEON__
#include <arm_neon.h>
typedef float32x4_t vec_float4 __attribute__((may_alias));
typedef uint32x4_t vec_uint4;
typedef uint16x8_t vec_ushort8;
typedef uint8x16_t vec_uchar16;
#else /* Generisch */
#define SCALAR_ONLY
typedef float vec_float4 __attribute__ ((__vector_size__ (16)));
typedef unsigned int vec_uint4 __attribute__ ((__vector_size__ (16)));
typedef unsigned short vec_ushort8 __attribute__ ((__vector_size__ (16)));
typedef unsigned char vec_uchar16 __attribute__ ((__vector_size__ (16)));
#endif

/*!
 * @abstract Definiert eine 4x4-Matrix
 * @discussion Die Struktur ist offensichtlich genug, sie enthaelt genau vier
 * Vektoren. Zu beachten ist, dass diese in Column-Major-Order gespeichert
 * werden, d.h. jeder Vektor ist eine Spalte der Matrix. Dies ist analog zu
 * OpenGL, widerspricht aber dem normalen Modell von C. Fuer viele Anwendungen
 * macht dies keinen Unterschied, aber einige Methoden gehen davon aus, dass
 * die Matrizen diesem Muster entsprechen.
 */
typedef struct __mat_float16 {
    vec_float4 x;
    vec_float4 y;
    vec_float4 z;
    vec_float4 w;
} mat_float16;
