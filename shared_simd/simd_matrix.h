#pragma once
/*
 *  simd_matrix.h
 *  graphicstest
 *
 *  Created by Torsten Kammer on 27.04.09.
 *  Copyright 2009 Ferroequinologist.de. All rights reserved.
 *
 */

#include "simd_functions.h"

/*!
 * @abstract Addiert zwei Matrizen komponentenweise
 */
static inline mat_float16 simd_mat_add(mat_float16 a, mat_float16 b)
{
    return (mat_float16) {a.x + b.x, a.y + b.y, a.z + b.z, a.w + b.w};
}

/*!
 * @abstract Subtrahiert zwei Matrizen komponentenweise
 */
static inline mat_float16 simd_mat_sub(mat_float16 a, mat_float16 b)
{
    return (mat_float16) {a.x - b.x, a.y - b.y, a.z - b.z, a.w - b.w};
}

/*!
 * @abstract Die Identitaetsmatrix
 * @discussion Kann man immer mal brauchen.
 */
static inline mat_float16 simd_mat_identity()
{
    return (mat_float16) {{1.0f, 0.0f, 0.0f, 0.0f}, {0.0f, 1.0f, 0.0f, 0.0f}, {0.0f, 0.0f, 1.0f, 0.0f}, {0.0f, 0.0f, 0.0f, 1.0f}};
}

/*!
 * @abstract Berechnet die Transposition der oberen 3x3 Teilmatrix die die Rotation darstellt.
 * @discussion Der w-Wert ist dabei nicht definiert
 */
static inline mat_float16 simd_mat_transpose3(const mat_float16 a)
{
	mat_float16 result;
#if defined(__SSE__)
	// Basierend auf _MM_TRANSPOSE4_PS wie in Apples xmmintrin.h definiert,
	// welches wiederum auf Intel C++ Compiler User Guide and Reference
	// basiert
	vec_float4 tp0 = _mm_unpacklo_ps(a.x, a.y);
	vec_float4 tp1 = _mm_unpacklo_ps(a.z, _mm_setzero_ps());
	vec_float4 tp2 = _mm_unpackhi_ps(a.x, a.y);
	vec_float4 tp3 = _mm_unpackhi_ps(a.z, _mm_setzero_ps());
	
	result.x = _mm_movelh_ps(tp0, tp1);
	result.y = _mm_movehl_ps(tp1, tp0);
	result.z = _mm_movelh_ps(tp2, tp3);
	result.w = _mm_movehl_ps(tp2, tp3);
#elif defined(__VEC__)
	// Basierend auf Apple-Beispielcode
    vec_float4 tp0 = vec_mergeh(a.x, a.z);
	vec_float4 tp1 = vec_mergeh(a.y, simd_zero());
	vec_float4 tp2 = vec_mergel(a.x, a.z);
	vec_float4 tp3 = vec_mergel(a.y, simd_zero());
	
	result.x = vec_mergeh(tp0, tp1);
	result.y = vec_mergel(tp0, tp1);
	result.z = vec_mergeh(tp2, tp3);
	result.w = vec_mergel(tp2, tp3);
#elif defined(__NEON__)
	float32x4x2_t x0 = vzipq_f32(a.x, a.y);
	float32x4x2_t x1 = vzipq_f32(a.z, simd_zero());
	
	result.x = vcombine_f32(vget_low_f32(x0.val[0]), vget_low_f32(x1.val[0]));
	result.z = vcombine_f32(vget_low_f32(x0.val[1]), vget_low_f32(x1.val[1]));
	result.y = vcombine_f32(vget_high_f32(x0.val[0]), vget_high_f32(x1.val[0]));
	result.w = vcombine_f32(vget_high_f32(x0.val[1]), vget_high_f32(x1.val[1]));
#else
	result = a;
	const float* restrict aF = (const float *) &a;
	float* restrict resultF = (float *) &result;
	
	for (unsigned i = 0; i < 3; i++)
		for (unsigned j = 0; j < 3; j++)
			resultF[i*4 + j] = aF[j*4 + i];
#endif
	return result;
}

/*!
 * @abstract Rotiert einen Vektor um eine Matrix.
 */
static inline vec_float4 simd_mat_vecrotate(const mat_float16 m, const vec_float4 v)
{
#if defined(__NEON__)
	return vmlaq_n_f32(vmlaq_n_f32(vmulq_n_f32(m.x, vgetq_lane_f32(v, 0)), m.y, vgetq_lane_f32(v, 1)), m.z, vgetq_lane_f32(v, 2));
#else
    return simd_splat(v, 0) * m.x + simd_splat(v, 1) * m.y + simd_splat(v, 2) * m.z;
#endif
}

/*!
 * @abstract Macht eine Vektor-Matrix-Rotation rückgängig
 */
static inline vec_float4 simd_mat_vecunrotate(const mat_float16 m, const vec_float4 v)
{
	return simd_mat_vecrotate(simd_mat_transpose3(m), v);
}

/*!
 * @abstract Multipliziert einen Vektor it einer Matrix.
 */
static inline vec_float4 simd_mat_vecmul(const mat_float16 m, const vec_float4 v)
{
#if defined(__NEON__)
	return vmlaq_n_f32(simd_mat_vecrotate(m, v), m.w, vgetq_lane_f32(v, 3));
#else
    return simd_mat_vecrotate(m, v) + simd_splat(v, 3) * m.w;
#endif
}

/*!
 * @abstract Berechnet das Matrix-Produkt zweier Matrizen
 * @discussion Berechnet a*b im klassischen Sinne. Die Funktion geht davon aus,
 * dass die Matrix in Column-Major-Order gespeichert ist. Falls nicht, muss die
 * Ausführungsreihenfolge umgedreht werden.
 */
static inline mat_float16 simd_mat_mul(const mat_float16 a, const mat_float16 b)
{
    return (mat_float16) { simd_mat_vecmul(a, b.x), simd_mat_vecmul(a, b.y), simd_mat_vecmul(a, b.z), simd_mat_vecmul(a, b.w) };
}

/*!
 * @abstract Berechnet das Inverse der Matrix
 * @discussion Diese Funktion geht strikt davon aus, dass es sich um eine affine
 * Transformationsmatrix in Column-Major-Order handelt. Bei allgemeinen
 * 4x4-Matrizen versagt sie.
 */
static inline mat_float16 simd_mat_inverse(mat_float16 a)
{
    // 1. Schritt: Matrix transponieren
	//	Theoretisch nicht nötig für w, schadet aber auch nicht da es vollständig
	//	überschrieben wird und nichts davon abhängt.
    mat_float16 result = simd_mat_transpose3(a);
    
    // 2. Schritt: w berechnen
#if defined(__NEON__)
	result.w = vnegq_f32(vmlaq_n_f32(vmlaq_n_f32(vmulq_n_f32(result.x, vgetq_lane_f32(a.w, 0)), result.y, vgetq_lane_f32(a.w, 1)), result.z, vgetq_lane_f32(a.w, 2))) + simd_e_w;
#else
	result.w =  -(simd_splat(a.w, 0) * result.x + simd_splat(a.w, 1) * result.y + simd_splat(a.w, 2) * result.z) + simd_e_w;
#endif
    return result;
}

static inline mat_float16 simd_mat_unit_directional(const vec_float4 unitDir, const vec_float4 position)
{
	mat_float16 result;
	result.x = unitDir;
	result.z = simd_normalize_e(simd_cross3(result.x, simd_e_y));
	result.y = simd_normalize_e(simd_cross3(result.z, result.x));
	result.w = position;
	return result;
}


static inline mat_float16 simd_mat_directional(const vec_float4 dir, const vec_float4 position)
{
	return simd_mat_unit_directional(simd_normalize_e(dir), position);
}

static inline mat_float16 simd_mat_positional(const vec_float4 position)
{
	return (mat_float16) {{1.0f, 0.0f, 0.0f, 0.0f}, {0.0f, 1.0f, 0.0f, 0.0f}, {0.0f, 0.0f, 1.0f, 0.0f}, position};
}

static inline mat_float16 simd_mat_lookat(vec_float4 direction, vec_float4 camPosition)
{
	mat_float16 result;
	result.x = simd_normalize_e(simd_cross3(direction, simd_e_y));
	result.y = simd_normalize_e(simd_cross3(result.x, direction));
	result.z = simd_normalize_e(-direction);
	result.w = camPosition;
	
	return simd_mat_inverse(result);
}

/*!
 * @abstract Berechnet eine Rotationsmatrix analog zu glRotate{fd}
 * @discussion Prinzipiell ist glRotate{fd} wohl bekannt. Zu beachten sind
 * hier: Der Winkel wird in Radian statt Grad geliefert. Die Achse (oder
 * genauer ihre ersten drei Elemente) muessen schon Einheitslaenge haben, also
 * eventuell normalisiert werden. Die letze Komponente muss 0 sein, ansonsten
 * gibt es eventuell inkorrekte Ergebnisse.
 */
static inline mat_float16 simd_mat_rotate(float angleInRadian, vec_float4 axis)
{
    /* Ansatz:
     * Gemäß Redbook ist die Formel für eine Rotationsmatrix:
     * M = uu^T  + (cos(alpha)) (I - uu^T) + (sin(alpha)) * ((0 z -y)^t (-z 0 x)^t (y -x 0)^t)
     * Dies können wir umformulieren zu
     * M = uu^T (1 - cos(alpha)) + I * cos(alpha) + (sin(alpha)) * ((0 z -y)^t (-z 0 x)^t (y -x 0)^t)
     * D.h. für Spalte i haben wir
     * M[i] = u * splat(u, i) * ((1 1 1) - cos(alpha)*(1 1 1)) + ((1 0 0) >> i) * cos(alpha) + (sin(alpha)) * entweder (0 z -y), (-z 0 x) oder (y -x 0)
     * Einige Aspekte davon sind konstant über alle Spalten, cos*I laesst sich
	 * durch eine Verschiebung zwischen den Spalten realisieren. Wirklich
	 * interessant ist nur der Sinus-Teil, da hier geschuffelt werden muss und
	 * gleichzeitig auch, abhaengig vom Code, negiert. Eine Auswahl zwischen
	 * zwei Vektoren beim Shuffle ist am sinnvollsten, aber es findet hier eine
	 * Begrenzung durch SSE statt: Die ersten beiden Werte des Ergebnisses
	 * muessen aus dem ersten, die zweiten aus dem zweiten Argumentvektor
	 * kommen. Daher ist nicht einer negiert und einer positiv, sondernd beide
	 * durchmischt, was den Code zweifellos schwieriger zu lesen macht.
     */
    vec_float4 sin = simd_splatf(sinf(angleInRadian));
    vec_float4 cos = simd_splatf(cosf(angleInRadian));
    
    vec_float4 one_minus_c_times_axis = (simd_splatf(1.0f) - cos) * axis;
    cos = simd_e_x * cos;
    vec_float4 sin_times_axis_a = axis * sin * simd_make(1.0f, -1.0f, 1.0f, -1.0f); // +X -Y +Z 0
    vec_float4 sin_times_axis_b = -sin_times_axis_a; // -X +Y -Z 0
    
    mat_float16 result;
    result.x = one_minus_c_times_axis * simd_splat(axis, 0) + cos + simd_mix(sin_times_axis_a, sin_times_axis_a, 3, 2, 1, 3); // 0 Z -Y 0
    cos = simd_shuffle(cos, 3, 0, 3, 3);
    result.y = one_minus_c_times_axis * simd_splat(axis, 1) + cos + simd_mix(sin_times_axis_b, sin_times_axis_a, 2, 3, 0, 3); // -Z 0 X 0
    cos = simd_shuffle(cos, 3, 3, 1, 3); // Beachte: Wert steht hier in cos[1] wegen oben. Generell ist solcher Code auf SSE sinnvoller, da SSE destruktiv arbeitet
    result.z = one_minus_c_times_axis * simd_splat(axis, 2) + cos + simd_mix(sin_times_axis_b, sin_times_axis_b, 1, 0, 3, 3); // Y -X 0 0
    result.w = simd_e_w;
    
    return result;
}

static inline mat_float16 simd_mat_extractrotation(mat_float16 a)
{
	return (mat_float16) { a.x, a.y, a.z, simd_e_w };
}

/*!
 * @abstract Bequemlichkeitsmethode um Euler-Winkel zu erstellen.
 */
mat_float16 simd_mat_euler(vec_float4 angles, vec_float4 position);
