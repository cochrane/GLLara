//
//  GLLMeshObj.h
//  GLLara
//
//  Created by Torsten Kammer on 12.09.12.
//  Copyright (c) 2012 Torsten Kammer. All rights reserved.
//

#import "GLLMesh.h"

#import "GLLObjFile.h"

@interface GLLMeshObj : GLLMesh

- (id)initWithObjFile:(GLLObjFile *)file range:(const GLLObjFile::MaterialRange &)range;

@end
