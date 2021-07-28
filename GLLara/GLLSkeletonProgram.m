//
//  GLLSkeletonProgram.m
//  GLLara
//
//  Created by Torsten Kammer on 25.09.12.
//  Copyright (c) 2012 Torsten Kammer. All rights reserved.
//

#import "GLLSkeletonProgram.h"

#import <OpenGL/gl3.h>

#import "GLLUniformBlockBindings.h"
#import "GLLVertexFormat.h"

@implementation GLLSkeletonProgram

- (id)initWithResourceManager:(GLLResourceManager *)manager error:(NSError *__autoreleasing*)error;
{
    if (!(self = [self initWithFragmentShaderName:@"Skeleton.fs" geometryShaderName:nil vertexShaderName:@"Skeleton.vs" additionalDefines:@{} usedTexCoords:[NSIndexSet indexSet] resourceManager:manager error:error])) return nil;
    
    GLuint transformUniformBlockIndex = glGetUniformBlockIndex(self.programID, "Transform");
    NSAssert(transformUniformBlockIndex != GL_INVALID_INDEX, @"Transform uniform index for skeleton program cannot be invalid");
    glUniformBlockBinding(self.programID, transformUniformBlockIndex, GLLUniformBlockBindingTransforms);
    
    return self;
}

- (void)bindAttributeLocations
{
    glBindAttribLocation(self.programID, GLLVertexAttribPosition, "position");
    glBindAttribLocation(self.programID, GLLVertexAttribColor, "color");
}

@end
