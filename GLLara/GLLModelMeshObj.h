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

@interface GLLModelMeshObj : GLLModelMesh

- (id)initWithObjFile:(GLLObjFile *)file mtlFiles:(const std::vector<GLLMtlFile *> &)mtlFiles range:(const GLLObjFile::MaterialRange &)range inModel:(GLLModel *)model error:(NSError *__autoreleasing*)error;

@end
