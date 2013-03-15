//
//  GLLItemMesh+OBJExport.h
//  GLLara
//
//  Created by Torsten Kammer on 19.09.12.
//  Copyright (c) 2012 Torsten Kammer. All rights reserved.
//

#import "GLLItemMesh.h"

#import "simd_types.h"

/*!
 * @abstract Methods for exporting a posed item to an OBJ file.
 */
@interface GLLItemMesh (OBJExport)

+ (NSString *)relativePathFrom:(NSURL *)ownLocation to:(NSURL *)textureLocation;

@property (nonatomic, readonly) BOOL willLoseDataWhenConvertedToOBJ;
- (NSString *)writeMTLWithBaseURL:(NSURL *)baseURL;
- (NSString *)writeOBJWithTransformations:(const mat_float16 *)transforms baseIndex:(uint32_t)baseIndex includeColors:(BOOL)includeColors;

@end
