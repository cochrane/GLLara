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

- (instancetype)initWithAttributes:(NSArray<GLLVertexAttrib *>*)attributes countOfVertices:(NSUInteger)countOfVertices hasIndices:(BOOL)hasIndices;

@property (nonatomic, readonly, copy) NSArray<GLLVertexAttrib *>* attributes;

// Number of bytes for storing an index element. Only valid values are 1, 2 and 4, or 0 if there is no element buffer
@property (nonatomic, readonly, assign) NSUInteger numElementBytes;

@property (nonatomic, assign, readonly) NSUInteger stride;

@end

#endif
