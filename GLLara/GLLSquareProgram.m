//
//  GLLSquareProgram.m
//  GLLara
//
//  Created by Torsten Kammer on 14.09.12.
//  Copyright (c) 2012 Torsten Kammer. All rights reserved.
//

#import "GLLSquareProgram.h"

#import <OpenGL/gl3.h>

@implementation GLLSquareProgram

- (id)initWithResourceManager:(GLLResourceManager *)manager error:(NSError *__autoreleasing*)error;
{
    if (!(self = [self initWithName:@"internal-square" fragmentShaderName:@"Square.fs" geometryShaderName:nil vertexShaderName:@"Square.vs" additionalDefines:@{} resourceManager:manager error:error])) return nil;
    
    glUniform1i(glGetUniformLocation(self.programID, "texImage"), 0);
    
    return self;
}

- (void)bindAttributeLocations
{
    glBindAttribLocation(self.programID, 0, "position");
}

@end
