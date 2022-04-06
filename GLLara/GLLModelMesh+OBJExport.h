//
//  GLLModelMesh+OBJExport.h
//  GLLara
//
//  Created by Torsten Kammer on 19.09.12.
//  Copyright (c) 2012 Torsten Kammer. All rights reserved.
//

#import "GLLara-Swift.h"

#import "simd_types.h"

/*!
 * @abstract Methods for exporting a posed mesh to an OBJ file.
 */
@interface GLLModelMesh (OBJExport)

- (NSString *)writeOBJWithTransformations:(const mat_float16 *)transforms baseIndex:(uint32_t)baseIndex includeColors:(BOOL)includeColors;

@end
