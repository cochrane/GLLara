//
//  GLLShader.h
//  GLLara
//
//  Created by Torsten Kammer on 02.09.12.
//  Copyright (c) 2012 Torsten Kammer. All rights reserved.
//

#import <Foundation/Foundation.h>
#import <OpenGL/gltypes.h>

@interface GLLShader : NSObject

- (id)initWithSource:(NSString *)source type:(GLenum)type;

- (void)unload;

@property (nonatomic, assign, readonly) GLenum type;
@property (nonatomic, assign, readonly) GLuint shaderID;

@end
