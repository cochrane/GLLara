//
//  GLLVertexAttribAccesorSet.h
//  GLLara
//
//  Created by Torsten Kammer on 07.04.21.
//  Copyright © 2021 Torsten Kammer. All rights reserved.
//

#import <Foundation/Foundation.h>

#import "GLLVertexAttrib.h"

NS_ASSUME_NONNULL_BEGIN

@class GLLVertexAttribAccessor;
@class GLLVertexFormat;

@interface GLLVertexAttribAccessorSet : NSObject

- (instancetype)initWithAccessors:(NSArray<GLLVertexAttribAccessor *> *)accessors;

- (GLLVertexAttribAccessorSet *)setByCombiningWith:(GLLVertexAttribAccessorSet *)other;

@property (nonatomic, readonly, copy) NSArray<GLLVertexAttribAccessor *> * accessors;

- (GLLVertexAttribAccessor *__nullable)accessorForSemantic:(enum GLLVertexAttribSemantic)semantic layer:(NSUInteger)layer;
- (GLLVertexAttribAccessor *__nullable)accessorForSemantic:(enum GLLVertexAttribSemantic)semantic;

- (GLLVertexFormat *)vertexFormatWithVertexCount:(NSUInteger)count hasIndices:(BOOL)hasIndices;

@end

NS_ASSUME_NONNULL_END
