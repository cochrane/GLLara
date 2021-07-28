//
//  GLLShader.m
//  GLLara
//
//  Created by Torsten Kammer on 02.09.12.
//  Copyright (c) 2012 Torsten Kammer. All rights reserved.
//

#import "GLLShader.h"

#import <OpenGL/gl3.h>

@implementation GLLShader

- (id)initWithSource:(NSString *)sourceString name:(NSString *)name additionalDefines:(NSDictionary *)defines usedTexCoords:(NSIndexSet *)texCoords type:(GLenum)type error:(NSError *__autoreleasing*)error;
{
    if (!(self = [super init])) return nil;
    
    if (!sourceString)
    {
        if (error)
            *error = [NSError errorWithDomain:@"OpenGL" code:1 userInfo:@{ NSLocalizedDescriptionKey : [NSString stringWithFormat:NSLocalizedString(@"The source code shader \"%@\" could not be found", @"GLLShader no source message description"), name],
                                                                           NSLocalizedRecoverySuggestionErrorKey : NSLocalizedString(@"Please inform a developer of this problem.", @"No shader there wtf?")
                                                                           }];
        return nil;
    }
    
    // Find all lines that follow the format for tex coord lines. Those start with ## and have %ld to replace the items
    NSRegularExpression *expression = [NSRegularExpression regularExpressionWithPattern:@"^\\$\\$(.*)$" options:NSRegularExpressionAnchorsMatchLines error:NULL];
    NSMutableString *transformedSource = [[NSMutableString alloc] initWithString:sourceString];
    NSTextCheckingResult *result = nil;
    while ((result = [expression firstMatchInString:transformedSource options:0 range:NSMakeRange(0, transformedSource.length)]) != nil) {
        // Found one. Instantiate it for each item
        NSString *pattern = [transformedSource substringWithRange:[result rangeAtIndex:1]];
        NSMutableString *replacement = [[NSMutableString alloc] init];
        for (NSInteger index = texCoords.firstIndex; index != NSNotFound; index = [texCoords indexGreaterThanIndex:index]) {
            // This would be a security vulnerability if we ever allowed shader source code from outside
            [replacement appendFormat:pattern, index];
        }
        [transformedSource replaceCharactersInRange:result.range withString:replacement];
    }
    
    _name = [name copy];
    
    _shaderID = glCreateShader(type);
    const GLsizei sourcesLength = (GLsizei) (2 + defines.count);
    const GLchar **sources = calloc(sizeof(GLchar *), sourcesLength);
    GLsizei *lengths = calloc(sizeof(GLsizei), sourcesLength);
    
    sources[0] = "#version 330\n";
    
    GLsizei defined = 1;
    for (NSString *key in defines) {
        NSString *value = defines[key];
        NSString *define = [NSString stringWithFormat:@"#define %@ %@\n", key, value];
        sources[defined++] = [define UTF8String];
    }
    
    sources[sourcesLength - 1] = [transformedSource UTF8String];
    for (GLsizei i = 0; i < sourcesLength; i++)
        lengths[i] = (GLsizei) strlen(sources[i]);
    glShaderSource(_shaderID, sourcesLength, sources, lengths);
    glCompileShader(_shaderID);
    free(sources);
    free(lengths);
    
    GLint compileStatus;
    glGetShaderiv(_shaderID, GL_COMPILE_STATUS, &compileStatus);
    if (compileStatus != GL_TRUE)
    {
        GLsizei length;
        glGetShaderiv(_shaderID, GL_INFO_LOG_LENGTH, &length);
        GLchar log[length+1];
        glGetShaderInfoLog(_shaderID, length+1, NULL, log);
        log[length] = '\0';
        
        if (error)
            *error = [NSError errorWithDomain:@"OpenGL" code:1 userInfo:@{ NSLocalizedDescriptionKey : [NSString stringWithFormat:NSLocalizedString(@"The shader \"%@\" could not be compiled properly", @"GLLShader error message description"), name],
                                                                           NSLocalizedFailureReasonErrorKey : [NSString stringWithFormat:NSLocalizedString(@"Message from OpenGL driver: %s", "No shade there wtf?"), log],
                                                                           NSLocalizedRecoverySuggestionErrorKey : NSLocalizedString(@"Please inform a developer of this problem.", @"No shader there wtf?")
                                                                           }];
        NSLog(@"compile error in shader %@: %s", _name, log);
        [self unload];
        return nil;
    }
    
    return self;
}

- (void)dealloc
{
    NSAssert(_shaderID == 0 && _type == 0, @"Did not call unload before deallocating");
}

- (void)unload;
{
    glDeleteShader(self.shaderID);
    _shaderID = 0;
    _type = 0;
}

@end
