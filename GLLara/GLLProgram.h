//
//  GLLProgram.h
//  GLLara
//
//  Created by Torsten Kammer on 02.09.12.
//  Copyright (c) 2012 Torsten Kammer. All rights reserved.
//

#import <Foundation/Foundation.h>
#import <OpenGL/gltypes.h>

@class GLLShader;

@interface GLLProgram : NSObject

- (id)initWithVertexShader:(GLLShader *)vertex geometryShader:(GLLShader *)geometry fragmentShader:(GLLShader *)fragment;

- (void)unload;

@property (nonatomic, assign, readonly) GLuint programID;

@end
