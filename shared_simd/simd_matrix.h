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
 * @abstract Rotiert einen Vektor um eine Matrix.
 */
static inline vec_float4 simd_mat_vecrotate(const mat_float16 m, const vec_float4 v)
{
#if defined(__NEON__)
    return vmlaq_n_f32(vmlaq_n_f32(vmulq_n_f32(m.x, vgetq_lane_f32(v, 0)), m.y, vgetq_lane_f32(v, 1)), m.z, vgetq_lane_f32(v, 2));
#else
    return simd_splat(v, 0) * m.columns[0] + simd_splat(v, 1) * m.columns[1] + simd_splat(v, 2) * m.columns[2];
#endif
}

static inline mat_float16 simd_mat_unit_directional(const vec_float4 unitDir, const vec_float4 position)
{
    mat_float16 result;
    result.columns[0] = unitDir;
    result.columns[2] = simd_fast_normalize(simd_cross3(result.columns[0], simd_e_y));
    result.columns[1] = simd_fast_normalize(simd_cross3(result.columns[2], result.columns[0]));
    result.columns[3] = position;
    return result;
}

static inline mat_float16 simd_mat_directional(const vec_float4 dir, const vec_float4 position)
{
    return simd_mat_unit_directional(simd_fast_normalize(dir), position);
}

static inline mat_float16 simd_mat_positional(const vec_float4 position)
{
    mat_float16 result = matrix_identity_float4x4;
    result.columns[3] = position;
    return result;
}

static inline mat_float16 simd_mat_lookat(vec_float4 direction, vec_float4 camPosition)
{
    mat_float16 result;
    result.columns[0] = simd_fast_normalize(simd_cross3(direction, simd_e_y));
    result.columns[1] = simd_fast_normalize(simd_cross3(result.columns[0], direction));
    result.columns[2] = simd_fast_normalize(-direction);
    result.columns[3] = camPosition;
    
    return simd_inverse(result);
}

static inline simd_float4 simd_mat_vecunrotate(const matrix_float4x4 matrix, const simd_float4 vector) {
    // TODO is this equal to vector * matrix?
    return simd_mul(simd_transpose(matrix), vector);
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
    result.columns[0] = one_minus_c_times_axis * simd_splat(axis, 0) + cos + simd_mix(sin_times_axis_a, sin_times_axis_a, 3, 2, 1, 3); // 0 Z -Y 0
    cos = simd_shuffle(cos, 3, 0, 3, 3);
    result.columns[1] = one_minus_c_times_axis * simd_splat(axis, 1) + cos + simd_mix(sin_times_axis_b, sin_times_axis_a, 2, 3, 0, 3); // -Z 0 X 0
    cos = simd_shuffle(cos, 3, 3, 1, 3); // Beachte: Wert steht hier in cos[1] wegen oben. Generell ist solcher Code auf SSE sinnvoller, da SSE destruktiv arbeitet
    result.columns[2] = one_minus_c_times_axis * simd_splat(axis, 2) + cos + simd_mix(sin_times_axis_b, sin_times_axis_b, 1, 0, 3, 3); // Y -X 0 0
    result.columns[3] = simd_e_w;
    
    return result;
}

/*!
 * @abstract Bequemlichkeitsmethode um Euler-Winkel zu erstellen.
 */
mat_float16 simd_mat_euler(vec_float4 angles, vec_float4 position);
