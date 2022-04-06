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

- (instancetype)initWithSemantic:(enum GLLVertexAttribSemantic)semantic layer:(NSInteger) layer size:(enum GLLVertexAttribSize)size componentType:(enum GLLVertexAttribComponentType)type dataBuffer:(NSData *__nullable)dataBuffer offset:(NSInteger)dataOffset stride:(NSInteger)stride;

- (instancetype)initWithAttribute:(GLLVertexAttrib *)attribute dataBuffer:(NSData *__nullable)dataBuffer offset:(NSInteger)dataOffset stride:(NSInteger)stride;

@property (nonatomic, readonly, copy) GLLVertexAttrib *attribute;
@property (nonatomic, readonly, retain) NSData *__nullable dataBuffer;
@property (nonatomic, readonly, assign) NSInteger dataOffset;
@property (nonatomic, readonly, assign) NSInteger stride;

- (NSInteger)offsetForElement:(NSInteger)index;
- (const void *)elementAt:(NSInteger)index;
- (NSData *)elementDataAt:(NSInteger)index;

@end

NS_ASSUME_NONNULL_END
