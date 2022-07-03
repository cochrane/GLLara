#pragma once
/*
 *  simd_types.h
 *  LandscapeCreator
 *
 *  Created by Torsten Kammer on 04.09.09.
 *  Copyright 2009 __MyCompanyName__. All rights reserved.
 *
 */

#include <simd/simd.h>

/*!
 * @abstract Datentyp für Vektor
 * @discussion Der Standard-Datentyp für SIMD speichert vier floats. Der Name
 * ist gleich dem Standard-Namen, den IBM fuer den Cell (sowohl PPU als auch
 * SPU) verwendet.
 */
typedef vector_float4 vec_float4;
typedef vector_uint4 vec_uint4;
typedef vector_ushort8 vec_ushort8;
typedef vector_uchar16 vec_uchar16;

/*!
 * @abstract Definiert eine 4x4-Matrix
 * @discussion Die Struktur ist offensichtlich genug, sie enthaelt genau vier
 * Vektoren. Zu beachten ist, dass diese in Column-Major-Order gespeichert
 * werden, d.h. jeder Vektor ist eine Spalte der Matrix. Dies ist analog zu
 * OpenGL, widerspricht aber dem normalen Modell von C. Fuer viele Anwendungen
 * macht dies keinen Unterschied, aber einige Methoden gehen davon aus, dass
 * die Matrizen diesem Muster entsprechen.
 */
typedef matrix_float4x4 mat_float16;
