//
//  GLLModelMeshObj.h
//  GLLara
//
//  Created by Torsten Kammer on 12.09.12.
//  Copyright (c) 2012 Torsten Kammer. All rights reserved.
//

#import "GLLModelMesh.h"

#import "GLLMtlFile.h"
#import "GLLObjFile.h"

/*!
 * @abstract A Model Mesh that comes from an OBJ file.
 * @discussion Meshes are created on a per-material basis for OBJ files. They
 * have only one set of texture coordinates, but tangents are created
 * automatically.
 */
@interface GLLModelMeshObj : GLLModelMesh

- (id)initWithObjFile:(GLLObjFile *)file mtlFiles:(const std::vector<GLLMtlFile *> &)mtlFiles range:(const GLLObjFile::MaterialRange &)range inModel:(GLLModel *)model error:(NSError *__autoreleasing*)error;

@end
