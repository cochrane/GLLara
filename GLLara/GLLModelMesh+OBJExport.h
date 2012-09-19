//
//  GLLModelMesh+OBJExport.h
//  GLLara
//
//  Created by Torsten Kammer on 19.09.12.
//  Copyright (c) 2012 Torsten Kammer. All rights reserved.
//

#import "GLLModelMesh.h"

#import "simd_types.h"

@interface GLLModelMesh (OBJExport)

- (NSString *)writeOBJWithTransformations:(const mat_float16 *)transforms baseIndex:(uint32_t)baseIndex includeColors:(BOOL)includeColors;

@end
