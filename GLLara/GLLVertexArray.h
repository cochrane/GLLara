//
//  GLLVertexArray.h
//  GLLara
//
//  Created by Torsten Kammer on 16.11.15.
//  Copyright (c) 2015 Torsten Kammer. All rights reserved.
//

#import <Foundation/Foundation.h>

#import "GLLDrawState.h"
#import "GLLVertexAttrib.h"

@class GLLVertexAttribAccessorSet;
@class GLLVertexFormat;

@interface GLLVertexArray : NSObject

- (id)initWithFormat:(GLLVertexFormat *)format;

@property (nonatomic, readonly, copy) GLLVertexFormat *format;

- (void)addVertices:(GLLVertexAttribAccessorSet *)vertexAccessors count:(NSUInteger)countOfVertices elements:(NSData *)elements elementsType:(GLLVertexAttribComponentType)elementsType;

@property (nonatomic, readonly, assign) NSUInteger countOfVertices;
@property (nonatomic, readonly, assign) NSUInteger elementDataLength;

- (void)upload;
@property (nonatomic, readonly, assign) GLuint vertexArrayIndex;

- (void)unload;

@end
