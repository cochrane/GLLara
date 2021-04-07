//
//  GLLVertexAttribAccessor.h
//  GLLara
//
//  Created by Torsten Kammer on 06.04.21.
//  Copyright © 2021 Torsten Kammer. All rights reserved.
//

#import <Foundation/Foundation.h>

#import "GLLVertexAttrib.h"

NS_ASSUME_NONNULL_BEGIN

@interface GLLVertexAttribAccessor : NSObject

- (instancetype)initWithSemantic:(enum GLLVertexAttribSemantic)semantic layer:(NSUInteger) layer size:(enum GLLVertexAttribSize)size componentType:(enum GLLVertexAttribComponentType)type dataBuffer:(NSData *__nullable)dataBuffer offset:(NSUInteger)dataOffset stride:(NSUInteger)stride;

- (instancetype)initWithAttribute:(GLLVertexAttrib *)attribute dataBuffer:(NSData *__nullable)dataBuffer offset:(NSUInteger)dataOffset stride:(NSUInteger)stride;

@property (nonatomic, readonly, copy) GLLVertexAttrib *attribute;
@property (nonatomic, readonly, retain) NSData *__nullable dataBuffer;
@property (nonatomic, readonly, assign) NSUInteger dataOffset;
@property (nonatomic, readonly, assign) NSUInteger stride;

- (NSUInteger)offsetForElement:(NSUInteger)index;
- (const void *)elementAt:(NSUInteger)index;
- (NSData *)elementDataAt:(NSUInteger)index;

@end

NS_ASSUME_NONNULL_END
