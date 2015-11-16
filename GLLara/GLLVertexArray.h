//
//  GLLVertexArray.h
//  GLLara
//
//  Created by Torsten Kammer on 16.11.15.
//  Copyright (c) 2015 Torsten Kammer. All rights reserved.
//

#import <Foundation/Foundation.h>

#import "GLLDrawState.h"

@class GLLVertexFormat;

@interface GLLVertexArray : NSObject

- (id)initWithFormat:(GLLVertexFormat *)format;

@property (nonatomic, readonly, copy) GLLVertexFormat *format;

- (void)addVertices:(NSData *)vertices elements:(NSData *)elementsUInt32;

@property (nonatomic, readonly, assign) NSUInteger countOfVertices;
@property (nonatomic, readonly, assign) NSUInteger elementDataLength;

- (void)upload;
- (void)bindWithState:(GLLDrawState *)state;

- (void)unload;

@end
