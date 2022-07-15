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

union float4Union
{
    vec_float4 vec;
    float scalar[4];
};

static const vec_float4 simd_e_x = { 1.0f, 0.0f, 0.0f, 0.0f };
static const vec_float4 simd_e_y = { 0.0f, 1.0f, 0.0f, 0.0f };
static const vec_float4 simd_e_z = { 0.0f, 0.0f, 1.0f, 0.0f };
static const vec_float4 simd_e_w = { 0.0f, 0.0f, 0.0f, 1.0f };

/*!
 * @abstract Erzeugt einen Vektor
 * @discussion Schöner als das immer per Hand zu tun so.
 */
static inline vec_float4 simd_make(float a, float b, float c, float d)
{
    return (vec_float4) {a, b, c, d};
}

/*!
 * @abstract Reduziert einen Vektor auf 2D
 */
static inline vec_float4 simd_flatten(vec_float4 v)
{
    return v * simd_make(1.0f, 0.0f, 1.0f, 1.0f);
}

/*!
 * @abstract Holt ein Element aus dem Vektor
 * @discussion Achtung, das kann recht teuer sein.
 */
#if defined(__NEON__)
#define simd_extract(a, b) vgetq_lane_f32(a, b)
#else
static inline float simd_extract(vec_float4 a, int b) {
    return ((union float4Union) {a}).scalar[b];
}
#endif

/*!
 * @abstract Fügt ein Element in einen Vektor ein
 * @discussion Hallo!
 */
static inline vec_float4 simd_set(vec_float4 original, unsigned index, float value)
{
    //TODO: SSE und NEON Support
#if 0
#else
    union {
        vec_float4 vec;
        float scalars[4];
    } conv = { original };
    conv.scalars[index] = value;
    return conv.vec;
#endif
}

/*!
 * @abstract Verteilt einen Float auf alle Elemente eines Vektors
 * @discussion Vor allem für dynamische Daten, für konstante Daten kann es
 * sein, dass dies langsamer ist als (vec_float4) {a, a, a, a}
 */
static inline vec_float4 simd_splatf(float a)
{
#if defined(__PPU__)
    // Wichtig: PPU statt VEC, da diese Funktion nicht in normalem Altivec ist.
    return vec_splat(a);
#elif defined(__SPU__)
    return spu_splat(a);
#elif defined(__NEON__)
    return vdupq_n_f32(a);
#elif defined(__SSE__)
    return _mm_set1_ps(a);
#else
    // Altivec + SSE haben solche Funktionen nicht. Der Compiler kennt dieses
    // Muster aber und optimiert es unter Umständen etwas (vielleicht auch nicht)
    return (vec_float4) {a, a, a, a};
#endif
}

static inline vec_float4 simd_zero()
{
#ifdef __SSE__
    return _mm_setzero_ps();
#else
    return simd_splatf(0.0f);
#endif
}

static inline vec_float4 simd_scale(vec_float4 vec, float scalar)
{
#if defined(__NEON__)
    return vmulq_n_f32(vec, scalar);
#else
    return vec * simd_splatf(scalar);
#endif
}

static inline vec_float4 simd_smuladd(vec_float4 a, vec_float4 b, float c)
{
#if defined(__NEON__)
    return vmlaq_n_f32(a, b, c);
#else
    return simd_scale(b, c) + a;
#endif
}

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
 * @abstract Verteilt ein Element eines Vektors auf alle anderen
 * @discussion Vor allem, um anderen Code deutlich zu verkuerzen. index muss ein
 * konstanter Wert sein! Fuer SSE und Altivec muss dies ein Makro sein, und es
 * vereinfacht Sachen wenn es auch fuer alle anderen eins ist.
 */
#if defined(__VEC__)
// Nur Altivec hat eine spezifische Splat-Instruktion, alle anderen arbeiten
// ueber shuffles.
#define simd_splat(a, b) vec_splat((a), (b))
#elif defined(__VEC__)
#define simd_splat(a, b) vdupq_lane_f32((a), (b))
#else
#define simd_splat(a, b) simd_shuffle((a), (b), (b), (b), (b))
#endif /* __VEC__ */

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

/*!
 * @abstract Liefert das kleinste Element des Vektors
 */
static inline vec_float4 simd_minvalv(vec_float4 a)
{
    vec_float4 min01 = simd_min(simd_splat(a, 0), simd_splat(a, 1));
    vec_float4 min23 = simd_min(simd_splat(a, 2), simd_splat(a, 3));
    return simd_min(min01, min23);
}

/*!
 * @abstract Liefert das größte Element des Vektors
 */
static inline vec_float4 simd_maxvalv(vec_float4 a)
{
    vec_float4 max01 = simd_max(simd_splat(a, 0), simd_splat(a, 1));
    vec_float4 max23 = simd_max(simd_splat(a, 2), simd_splat(a, 3));
    return simd_max(max01, max23);
}

/*!
 * @abstract Berechnet floor des Eingabewertes
 */
static inline vec_float4 simd_floor(vec_float4 v)
{
    return v - simd_fract(v);
}

#pragma mark Integer-Berechnungen

/*!
 * @abstract Vereint zwei 32-bit Vektoren auf einen mit 16
 * @discussion Verhalten für Werte, die mit 16 Bit nicht dargestellt werden können, sind nicht definiert.
 */
static inline vec_ushort8 simd_conv32to16(const vec_uint4 a, const vec_uint4 b)
{
#if defined(__SSE__)
    return (vec_ushort8) _mm_packs_epi32((__m128i) a, (__m128i) b);
#elif defined(__VEC__)
    return vec_packsu(a, b);
#elif defined(__NEON__)
    return vcombine_u16(vmovn_u32(a), vmovn_u32(b));
#else
    const int *aI = (const int *) &a;
    const int *bI = (const int *) &b;
    
    return (vec_ushort8) { (unsigned short) aI[0], (unsigned short) aI[1], (unsigned short) aI[2], (unsigned short) aI[3], (unsigned short) bI[0], (unsigned short) bI[1], (unsigned short) bI[2], (unsigned short) bI[3] };
#endif
}

/*!
 * @abstract Vereint zwei 16-bit Vektoren auf einen mit 8
 * @discussion Verhalten für Werte, die mit 8 Bit nicht dargestellt werden können, sind nicht definiert.
 */
static inline vec_uchar16 simd_conv16to8(const vec_ushort8 a, const vec_ushort8 b)
{
#if defined(__SSE__)
    return (vec_uchar16) _mm_packs_epi16((__m128i) a, (__m128i) b);
#elif defined(__VEC__)
    return vec_packsu(a, b);
#elif defined(__NEON__)
    return vcombine_u8(vmovn_u16(a), vmovn_u16(b));
#else
    const unsigned short *aS = (const unsigned short *) &a;
    const unsigned short *bS = (const unsigned short *) &b;
    return (vec_uchar16) { (unsigned char) aS[0], (unsigned char) aS[1], (unsigned char) aS[2], (unsigned char) aS[3], (unsigned char) aS[4], (unsigned char) aS[5], (unsigned char) aS[6], (unsigned char) aS[7], (unsigned char) bS[0], (unsigned char) bS[1], (unsigned char) bS[2], (unsigned char) bS[3], (unsigned char) bS[4], (unsigned char) bS[5], (unsigned char) bS[6], (unsigned char) bS[7] };
#endif
}

#pragma mark Ebenengleichung

/*!
 * @abstract Berechnet eine Ebenengleichung in Parameterform
 * @discussion Erstellt aus dem gegebenen Richtungsvektor (muss nicht
 * Einheitslänge haben) und Punkt eine Ebenengleichung, so dass für jeden Punkt
 * der Abstand bestimmt werden kann, in dem simd_dot(punkt, ebene) berechnet
 * wird.
 */
static inline vec_float4 simd_plane(const vec_float4 normal, const vec_float4 position)
{
    vec_float4 unitNormal = simd_fast_normalize(normal);
    return simd_make_float4(unitNormal.xyz, -simd_dot(unitNormal, position));
}

#pragma mark Raytracing

/*!
 * @abstract Entfernung von Strahl und Punkt
 */
static inline float simd_rayDistance(const vec_float4 start, const vec_float4 direction, const vec_float4 point)
{
    const vec_float4 startToPoint = point - start;
    const vec_float4 normalizedDirection = simd_fast_normalize(direction);
    vec_float4 alongStart = simd_dot(startToPoint, normalizedDirection);
    alongStart = simd_max(alongStart, (vec_float4) { 0.0f, 0.0f, 0.0f, 0.0f});
    alongStart = simd_min(alongStart, (vec_float4) { 1.0f, 1.0f, 1.0f, 0.0f});
    const vec_float4 nearestPoint = start + normalizedDirection*alongStart;
    return simd_length(nearestPoint - point);
}

/*!
 * @abstract Berechnet ob und wenn ja wo ein Strahl auf eine axis-aligned bounding box trifft
 * @discussion Hier darf outFactor null sein.
 */
static inline int simd_rayIntersectsAABB(const vec_float4 start, const vec_float4 direction, const vec_float4 min, const vec_float4 max, vec_float4 *tStart, vec_float4 *tEnd)
{
    const vec_float4 zero = simd_zero();
    const vec_float4 one = simd_splatf(1.0f);
    
    vec_float4 startCorner = simd_select(min, max, direction > zero);
    vec_float4 endCorner = simd_select(max, min, direction > zero);
    
    vec_float4 startTs = simd_select((startCorner - start) / direction, zero, direction != zero);
    
    vec_float4 endTs = simd_select((endCorner - start) / direction, one, direction != zero);
    
    *tStart = simd_max(simd_maxvalv(startTs), zero);
    *tEnd = simd_min(simd_minvalv(endTs), one);
    
    return simd_all(*tStart <= one) && simd_all(*tEnd >= zero) && simd_all(*tStart <= *tEnd);
}

/*!
 * @abstract Berechnet ob und wenn ja wo ein Strahl auf ein Dreieck trifft
 * @discussion outFactor darf nicht null sein.
 */
static inline int simd_rayIntersectsTriangle(const vec_float4 start, const vec_float4 direction, const vec_float4 *points, vec_float4 *outFactor)
{
    const vec_float4 zero = simd_splatf(0.0f);
    const vec_float4 one = simd_splatf(1.0f);
    
    const vec_float4 p0p1 = points[1] - points[0];
    const vec_float4 p0p2 = points[2] - points[0];
    
    const vec_float4 normal = simd_cross3(p0p1, p0p2);
    
    //	n * p = n * (s + t*d) = n*s + n*d*t
    //	n(p-s) = ndt
    //	(n(p-s))/(n*d) = t
    
    *outFactor = simd_dot(normal, points[0]-start) / simd_dot(normal, direction);
    if (simd_any(*outFactor > one)) return 0;
    if (simd_any(*outFactor < zero)) return 0;
    
    const vec_float4 hitPoint = start + *outFactor * direction;
    const vec_float4 p0hp = hitPoint - points[0];
    
    //	dot00 = dot(v0, v0)
    //	dot01 = dot(v0, v1)
    //	dot02 = dot(v0, v2)
    //	dot11 = dot(v1, v1)
    //	dot12 = dot(v1, v2)
    //
    //	// Compute barycentric coordinates
    //	invDenom = 1 / (dot00 * dot11 - dot01 * dot01)
    //	u = (dot11 * dot02 - dot01 * dot12) * invDenom
    //	v = (dot00 * dot12 - dot01 * dot02) * invDenom
    //	
    //	// Check if point is in triangle
    //	return (u > 0) && (v > 0) && (u + v < 1)
    
    const vec_float4 dot00 = simd_dot(p0p1, p0p1);
    const vec_float4 dot01 = simd_dot(p0p1, p0p2);
    const vec_float4 dot02 = simd_dot(p0p1, p0hp);
    const vec_float4 dot11 = simd_dot(p0p2, p0p2);
    const vec_float4 dot12 = simd_dot(p0p2, p0hp);
    
    const vec_float4 invDenom = simd_splatf(1.0f) / (dot00 * dot11 - dot01 * dot01);
    const vec_float4 u = (dot11 * dot02 - dot01 * dot12) * invDenom;
    const vec_float4 v = (dot00 * dot12 - dot01 * dot02) * invDenom;
    
    return simd_all(u >= zero) && simd_all(v >= zero) && simd_all(u+v <= one);
}
