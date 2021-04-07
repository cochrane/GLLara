//
//  GLLVertexFormat.h
//  GLLara
//
//  Created by Torsten Kammer on 01.09.12.
//  Copyright (c) 2012 Torsten Kammer. All rights reserved.
//

#ifndef GLLara_GLLVertexFormat_h
#define GLLara_GLLVertexFormat_h

#import <Foundation/Foundation.h>

#import "GLLVertexAttrib.h"

@interface GLLVertexFormat : NSObject<NSCopying>

- (instancetype)initWithAttributes:(NSArray<GLLVertexAttrib *>*)attributes countOfVertices:(NSUInteger)countOfVertices;

@property (nonatomic, readonly, copy) NSArray<GLLVertexAttrib *>* attributes;

- (GLLVertexAttrib *)attribForSemantic:(enum GLLVertexAttribSemantic)attrib layer:(NSUInteger)layer;

@property (nonatomic, readonly, assign) BOOL hasBoneWeights;
@property (nonatomic, readonly, assign) BOOL hasTangents;
@property (nonatomic, readonly, assign) NSUInteger countOfUVLayers;
// Number of bytes for storing an element. Only valid values are 1, 2 and 4
@property (nonatomic, readonly, assign) NSUInteger numElementBytes;

@property (nonatomic, assign, readonly) NSUInteger stride;

@end

#endif
