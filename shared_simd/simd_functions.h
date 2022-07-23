/*
 *  simd_functions.h
 *  graphicstest
 *
 *  Created by Torsten Kammer on 23.04.09.
 *  Copyright 2009 __MyCompanyName__. All rights reserved.
 *
 */
#pragma once

/*!
 * @header simd_functions.h
 * @abstract Enthaelt allgemeine SIMD-Funktionen
 * @discussion Dieser Header enthaelt Funktionen fuer SIMD, speziell Vektoren.
 * Diese sind so ausgelegt, dass sie auf SSE1/SSE2, PowerPC mit Altivec (mit
 * oder ohne den zusätzlichen Funktionen der Cell-PPU) und Cell-SPUs laufen.
 *
 * Der Header geht nur dann richtig, wenn fuer SSE das Makro __SSE__, fuer
 * Altivec entweder das Makro __VEC__ oder __PPU__ (dann mit den PPU-
 * Erweiterungen) und fuer die SPU das Makro __SPU__ definiert ist (je nach dem,
 * fuer was gerade compiliert wird). Ausserdem geht er von GCC aus, was den
 * Seiteneffekt hat dass Addition, Subtraktion und komponentenweises
 * multiplizieren und dividieren ueber die normalen Operatoren +, -, / und *
 * geschehen kann. Daher sind keine Funktionen simd_add oder so enthalten.
 *
 * Um das ganze etwas uebersichtlicher zu halten sind auch keine Funktionen fuer
 * das Quadrat der Laenge (simd_dot(a, a) geht genauso) enthalten, denn die sind
 * eigentlich offensichtlich.
 *
 * Der Header muesste unter C99 und C++ gleich gut arbeiten.
 */

#include <math.h>
#include <stdint.h>
#include <stdio.h>

#if defined(TARGET_OS_MAC)
#include <Accelerate/Accelerate.h>
#endif

#include "simd_types.h"

static const vec_float4 simd_e_x = { 1.0f, 0.0f, 0.0f, 0.0f };
static const vec_float4 simd_e_y = { 0.0f, 1.0f, 0.0f, 0.0f };
static const vec_float4 simd_e_z = { 0.0f, 0.0f, 1.0f, 0.0f };
static const vec_float4 simd_e_w = { 0.0f, 0.0f, 0.0f, 1.0f };

/*!
 * @abstract Vertauscht Elemente eines Vektors
 * @discussion Fuer SSE muss die Maske immer eine Compilezeit-Konstante sein.
 * Die Argumente werden in logischer Reihenfolge angegeben, d.h. Identitaet ist
 * 0 1 2 3.
 *
 * Fuer SSE muss dies ein Makro sein.
 */
#if defined(__SSE__)
#define simd_shuffle(vec, a, b, c, d) ( (vec_float4) _mm_shuffle_epi32((__m128i) vec, _MM_SHUFFLE((d), (c), (b), (a))) )
#else
static inline vec_float4 simd_shuffle(vec_float4 vec, unsigned char a, unsigned char b, unsigned char c, unsigned char d)
{
#if defined(__VEC__)
    return vec_perm(vec, vec, (vector unsigned char) {(a)*4+0, (a)*4+1, (a)*4+2, (a)*4+3,  (b)*4+0, (b)*4+1, (b)*4+2, (b)*4+3,  (c)*4+0, (c)*4+1, (c)*4+2, (c)*4+3,  (d)*4+0, (d)*4+1, (d)*4+2, (d)*4+3});
#elif defined(__SPU__)
    return spu_shuffle(vec, vec, (vector unsigned char) {(a)*4+0, (a)*4+1, (a)*4+2, (a)*4+3,  (b)*4+0, (b)*4+1, (b)*4+2, (b)*4+3,  (c)*4+0, (c)*4+1, (c)*4+2, (c)*4+3,  (d)*4+0, (d)*4+1, (d)*4+2, (d)*4+3});
#else
    const float* value = (const float *) &vec;
    return (vec_float4) { value[a], value[b], value[c], value[d] };
#endif /* __VEC__ || __SPU__ */
}
#endif /* __SSE__ */

/*!
 * @abstract Vermischt und vertauscht die Elemente zweier Vektoren
 * @discussion Diese Funktion ist durch SSE begrenzt und daher bei weitem nicht
 * so mächtig, wie wünschenswert (und auf manchen anderen Architekturen
 * verfuegbar). Das Ergebnis ist vec1[a] vec1[b] vec2[c] vec2[d]
 */
#if defined(__SSE__)
#define simd_mix(vec1, vec2, a, b, c, d) ( _mm_shuffle_ps((vec1), (vec2), _MM_SHUFFLE((d), (c), (b), (a))) )
#else
static inline vec_float4 simd_mix(vec_float4 vec1, vec_float4 vec2, unsigned char a, unsigned char b, unsigned char c, unsigned char d)
{
#if defined(__VEC__)
    return vec_perm(vec1, vec2, (vector unsigned char) {(a)*4+0, (a)*4+1, (a)*4+2, (a)*4+3,  (b)*4+0, (b)*4+1, (b)*4+2, (b)*4+3,  16+(c)*4+0, 16+(c)*4+1, 16+(c)*4+2, 16+(c)*4+3,  16+(d)*4+0, 16+(d)*4+1, 16+(d)*4+2, 16+(d)*4+3});
#elif defined(__SPU__)
    return spu_shuffle(vec1, vec2, (vector unsigned char) {(a)*4+0, (a)*4+1, (a)*4+2, (a)*4+3,  (b)*4+0, (b)*4+1, (b)*4+2, (b)*4+3,  16+(c)*4+0, 16+(c)*4+1, 16+(c)*4+2, 16+(c)*4+3,  16+(d)*4+0, 16+(d)*4+1, 16+(d)*4+2, 16+(d)*4+3});
#else
    const float *value1 = (const float *) &vec1;
    const float *value2 = (const float *) &vec2;
    return (vec_float4) { value1[a], value1[b], value2[c], value2[d] };
#endif
}
#endif

/*!
 * @abstract Berechnet das Kreuzprodukt zweier Vektoren
 * @discussion Ignoriert die vierte Komponente voellig. Beim Ausgabevektor wird
 * sie auf 0 gesetzt, so lange sie vorher nicht was komisches (Nan, Infinity
 * etc.) war.
 */
static inline vec_float4 simd_cross3(const vec_float4 a, const vec_float4 b)
{
    return a.yzxw * b.zxyw - a.zxyw * b.yzxw;
}
