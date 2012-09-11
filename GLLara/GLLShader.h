//
//  GLLShader.h
//  GLLara
//
//  Created by Torsten Kammer on 02.09.12.
//  Copyright (c) 2012 Torsten Kammer. All rights reserved.
//

#import <Foundation/Foundation.h>
#import <OpenGL/gltypes.h>

/*!
 * @abstract A single shader.
 * @discussion Exactly what you'd expect.
 */
@interface GLLShader : NSObject

- (id)initWithSource:(NSString *)sourceString name:(NSString *)name type:(GLenum)type error:(NSError *__autoreleasing*)error;

- (void)unload;

@property (nonatomic, copy, readonly) NSString *name;
@property (nonatomic, assign, readonly) GLenum type;
@property (nonatomic, assign, readonly) GLuint shaderID;

@end
