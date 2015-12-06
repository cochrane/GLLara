//
//  GLLResourceManager.m
//  GLLara
//
//  Created by Torsten Kammer on 04.09.12.
//  Copyright (c) 2012 Torsten Kammer. All rights reserved.
//

#import "GLLResourceManager.h"

#import <OpenGL/gl3.h>
#import <OpenGL/gl3ext.h>

#import "GLLModel.h"
#import "GLLModelDrawData.h"
#import "GLLModelProgram.h"
#import "GLLUniformBlockBindings.h"
#import "GLLShader.h"
#import "GLLShaderDescription.h"
#import "GLLSkeletonProgram.h"
#import "GLLSquareProgram.h"
#import "GLLTexture.h"

struct GLLAlphaTestBlock
{
	GLuint mode;
	GLfloat reference;
};

@interface GLLResourceManager ()
{
	NSMutableDictionary *shaders;
	NSMutableDictionary *programs;
	NSMutableDictionary *textures;
	NSMutableDictionary *models;
}

- (NSData *)_dataForFilename:(NSString *)filename baseURL:(NSURL *)baseURL error:(NSError *__autoreleasing*)error;
- (NSString *)_utf8StringForFilename:(NSString *)filename baseURL:(NSURL *)baseURL error:(NSError *__autoreleasing*)error;
- (id)_valueForKey:(id)key from:(NSMutableDictionary *)dictionary ifNotFound:(id(^)())supplier;
- (id)_makeWithContext:(id(^)())supplier;

@end

static GLLResourceManager *sharedManager;

@implementation GLLResourceManager

+ (id)sharedResourceManager
{
	if (!sharedManager)
		sharedManager = [[GLLResourceManager alloc] init];
	
	return sharedManager;
}

- (id)init
{
	if (!(self = [super init])) return nil;
	
	NSOpenGLPixelFormatAttribute attribs[] = {
		NSOpenGLPFAOpenGLProfile, (NSOpenGLPixelFormatAttribute) NSOpenGLProfileVersion3_2Core,
		0
	};
	
	NSOpenGLPixelFormat *format = [[NSOpenGLPixelFormat alloc] initWithAttributes:attribs];
	_openGLContext = [[NSOpenGLContext alloc] initWithFormat:format shareContext:nil];
	[_openGLContext makeCurrentContext];
	NSAssert(_openGLContext, @"Should have an OpenGL context here");
	
	shaders = [[NSMutableDictionary alloc] init];
	programs = [[NSMutableDictionary alloc] init];
	textures = [[NSMutableDictionary alloc] init];
	models = [[NSMutableDictionary alloc] init];
	
	// Alpha test buffers
	glGenBuffers(1, &_alphaTestPassGreaterBuffer);
    glBindBufferBase(GL_UNIFORM_BUFFER, GLLUniformBlockBindingAlphaTest, _alphaTestPassGreaterBuffer);
    struct GLLAlphaTestBlock alphaBlock = { .mode = 1, .reference = .9 };
	glBufferData(GL_UNIFORM_BUFFER, sizeof(alphaBlock), &alphaBlock, GL_STATIC_DRAW);
	glGenBuffers(1, &_alphaTestPassLessBuffer);
	glBindBufferBase(GL_UNIFORM_BUFFER, GLLUniformBlockBindingAlphaTest, _alphaTestPassLessBuffer);
	alphaBlock.mode = 2;
	glBufferData(GL_UNIFORM_BUFFER, sizeof(alphaBlock), &alphaBlock, GL_STATIC_DRAW);
	
	return self;
}

- (void)dealloc;
{
	[self.openGLContext makeCurrentContext];
	
	[models.allValues makeObjectsPerformSelector:@selector(unload)];
	[textures.allValues makeObjectsPerformSelector:@selector(unload)];
	[programs.allValues makeObjectsPerformSelector:@selector(unload)];
	[shaders.allValues makeObjectsPerformSelector:@selector(unload)];
	
	models = nil;
	textures = nil;
	programs = nil;
	shaders = nil;
}

#pragma mark - Retrieving resources

- (GLLModelDrawData *)drawDataForModel:(GLLModel *)model error:(NSError *__autoreleasing*)error;
{
    return [self _valueForKey:model.baseURL from:models ifNotFound:^{
        return [[GLLModelDrawData alloc] initWithModel:model resourceManager:self error:error];
    }];
}

- (GLLModelProgram *)programForDescriptor:(GLLShaderDescription *)description withAlpha:(BOOL)alpha error:(NSError *__autoreleasing*)error;
{
    NSParameterAssert(description);
    
    NSDictionary *key = @{ @"identifier": description.programIdentifier,
                           @"alpha": @(alpha) };
    
    return [self _valueForKey:key from:programs ifNotFound:^{
        return [[GLLModelProgram alloc] initWithDescriptor:description alpha:alpha resourceManager:self error:error];
    }];
}

- (GLLTexture *)textureForURL:(NSURL *)textureURL error:(NSError *__autoreleasing*)error;
{
    return [self _valueForKey:textureURL from:textures ifNotFound:^{
        NSURL *effectiveURL = textureURL;
        NSData *textureData = [NSData dataWithContentsOfURL:textureURL options:NSDataReadingUncached error:error];
        if (!textureData)
        {
            // Second attempt: Maybe there is a default version of that in the bundle.
            // If not, then keep error from first read.
            effectiveURL = [[NSBundle mainBundle] URLForResource:textureURL.lastPathComponent withExtension:nil];
            if (!effectiveURL)
                return (GLLTexture *) nil;
        }
        return [[GLLTexture alloc] initWithURL:effectiveURL error:error];
    }];
}

- (GLLShader *)shaderForName:(NSString *)shaderName additionalDefines:(NSDictionary *)defines type:(GLenum)type baseURL:(NSURL *)baseURL error:(NSError *__autoreleasing*)error;
{
    NSParameterAssert(shaderName);
    NSParameterAssert(defines);
    
    NSDictionary *key = @{ @"name" : shaderName,
                           @"defines": defines };
    
    return [self _valueForKey:key from:shaders ifNotFound:^{
        NSString *shaderSource = [self _utf8StringForFilename:shaderName baseURL:baseURL error:error];
        if (!shaderSource) return (GLLShader *) nil;
        
        // Actual loading
        return [[GLLShader alloc] initWithSource:shaderSource name:shaderName additionalDefines:defines type:type error:error];
    }];
}

- (GLLProgram *)squareProgram
{
	if (!_squareProgram)
	{
        _squareProgram = [self _makeWithContext:^{
            return [[GLLSquareProgram alloc] initWithResourceManager:self error:NULL];
        }];
	}
	return _squareProgram;
}

- (GLuint)squareVertexArray
{
	if (!_squareVertexArray)
	{
        [self _makeWithContext:^{
            glGenVertexArrays(1, &_squareVertexArray);
            glBindVertexArray(_squareVertexArray);
            GLuint squareVBO;
            glGenBuffers(1, &squareVBO);
            glBindBuffer(GL_ARRAY_BUFFER, squareVBO);
            float coords[] = {
                -1.0f, -1.0f,
                1.0f, -1.0f,
                -1.0f, 1.0f,
                1.0f, 1.0f
            };
            glBufferData(GL_ARRAY_BUFFER, sizeof(coords), coords, GL_STATIC_DRAW);
            glEnableVertexAttribArray(0);
            glVertexAttribPointer(0, 2, GL_FLOAT, GL_FALSE, sizeof(GLfloat [2]), NULL);
            return (id) nil;
        }];
	}
	return _squareVertexArray;
}

- (GLLProgram *)skeletonProgram
{
	if (!_skeletonProgram)
    {
        _skeletonProgram = [self _makeWithContext:^{
            return [[GLLSquareProgram alloc] initWithResourceManager:self error:NULL];
        }];
	}
	return _skeletonProgram;
}

#pragma mark - OpenGL limits

- (NSInteger)maxAnisotropyLevel
{
    return [[self _makeWithContext:^{
        GLint maxAnisotropyLevel;
        glGetIntegerv(GL_MAX_TEXTURE_MAX_ANISOTROPY_EXT, &maxAnisotropyLevel);
        return @(maxAnisotropyLevel);
    }] integerValue];
}

#pragma mark - Testing

- (void)clearInternalCaches;
{
	[models.allValues makeObjectsPerformSelector:@selector(unload)];
	[textures.allValues makeObjectsPerformSelector:@selector(unload)];
	[programs.allValues makeObjectsPerformSelector:@selector(unload)];
	[shaders.allValues makeObjectsPerformSelector:@selector(unload)];

	[models removeAllObjects];
	[textures removeAllObjects];
	[programs removeAllObjects];
	[shaders removeAllObjects];
}

#pragma mark - Private methods

- (id)_makeWithContext:(id(^)())supplier;
{
    NSOpenGLContext *previous = [NSOpenGLContext currentContext];
    [self.openGLContext makeCurrentContext];
    id result = supplier();
    [previous makeCurrentContext];
    return result;
}

- (id)_valueForKey:(id)key from:(NSMutableDictionary *)dictionary ifNotFound:(id(^)())supplier;
{
    NSParameterAssert(key);
    id result = dictionary[key];
    if (!result)
    {
        result = [self _makeWithContext:supplier];
        dictionary[key] = result;
    }
    return result;

}

- (NSData *)_dataForFilename:(NSString *)filename baseURL:(NSURL *)baseURL error:(NSError *__autoreleasing*)error;
{
	NSString *actualFilename = [[filename componentsSeparatedByString:@"\\"] lastObject];
	
	NSURL *localURL = [NSURL URLWithString:actualFilename relativeToURL:baseURL];
	NSData *localData = [NSData dataWithContentsOfURL:localURL];
	if (localData) return localData;
	
	NSURL *resourceURL = [NSURL URLWithString:actualFilename relativeToURL:[[NSBundle mainBundle] resourceURL]];
	return [NSData dataWithContentsOfURL:resourceURL options:0 error:error];
}
- (NSString *)_utf8StringForFilename:(NSString *)filename baseURL:(NSURL *)baseURL error:(NSError *__autoreleasing*)error;
{
	NSData *data = [self _dataForFilename:filename baseURL:baseURL error:error];
	if (!data) return nil;
	
	return [[NSString alloc] initWithData:data encoding:NSUTF8StringEncoding];
}

@end
