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
#import <OpenGL/CGLRenderers.h>

#import "GLLModel.h"
#import "GLLModelDrawData.h"
#import "GLLModelProgram.h"
#import "GLLPreferenceKeys.h"
#import "GLLUniformBlockBindings.h"
#import "GLLShader.h"
#import "GLLSkeletonProgram.h"
#import "GLLSquareProgram.h"
#import "GLLTexture.h"

#import "GLLara-Swift.h"

struct GLLAlphaTestBlock
{
    GLuint mode;
    GLfloat reference;
};

@interface GLLResourceManager ()
{
    NSMutableDictionary *shaders;
    NSMutableDictionary<GLLShaderData*, GLLModelProgram *> *programs;
    NSMutableDictionary *textures;
    NSMutableDictionary *models;
}

- (NSData *)_dataForFilename:(NSString *)filename error:(NSError *__autoreleasing*)error;
- (NSString *)_utf8StringForFilename:(NSString *)filename error:(NSError *__autoreleasing*)error;
- (id)_valueForKey:(id)key from:(NSMutableDictionary *)dictionary ifNotFound:(id(^)(void))supplier;

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
    
    _metalDevice = MTLCreateSystemDefaultDevice();
    
    shaders = [[NSMutableDictionary alloc] init];
    programs = [[NSMutableDictionary alloc] init];
    textures = [[NSMutableDictionary alloc] init];
    models = [[NSMutableDictionary alloc] init];
    
    _library = [_metalDevice newDefaultLibrary];
    _pixelFormat = MTLPixelFormatBGRA8Unorm;
    
    // Alpha test buffers
    struct GLLAlphaTestBlock alphaBlock = { .mode = 1, .reference = .9 };
    _alphaTestPassGreaterBuffer = [_metalDevice newBufferWithBytes:&alphaBlock length:sizeof(alphaBlock) options:MTLResourceStorageModeManaged];
    
    struct GLLAlphaTestBlock alphaBlockPassLess = { .mode = 2, .reference = .9 };
    _alphaTestPassLessBuffer = [_metalDevice newBufferWithBytes:&alphaBlockPassLess length:sizeof(alphaBlock) options:MTLResourceStorageModeManaged];
    
    return self;
}

- (void)dealloc;
{
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

- (GLLModelProgram *)programForDescriptor:(GLLShaderData *)description error:(NSError *__autoreleasing*)error;
{
    NSParameterAssert(description);
    
    return [self _valueForKey:description from:programs ifNotFound:^{
        return [[GLLModelProgram alloc] initWithDescriptor:description resourceManager:self error:error];
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

- (GLLShader *)shaderForName:(NSString *)shaderName additionalDefines:(NSDictionary *)defines usedTexCoords:(NSIndexSet *)texCoords type:(GLenum)type error:(NSError *__autoreleasing*)error;
{
    NSParameterAssert(shaderName);
    NSParameterAssert(defines);
    
    NSDictionary *key = @{ @"name" : shaderName,
                           @"defines": defines,
                           @"texCoords": texCoords
    };
    
    return [self _valueForKey:key from:shaders ifNotFound:^{
        NSString *shaderSource = [self _utf8StringForFilename:shaderName error:error];
        if (!shaderSource) return (GLLShader *) nil;
        
        // Actual loading
        return [[GLLShader alloc] initWithSource:shaderSource name:shaderName additionalDefines:defines usedTexCoords:texCoords type:type error:error];
    }];
}

- (GLLProgram *)squareProgram
{
    if (!_squareProgram)
    {
        _squareProgram = [[GLLSquareProgram alloc] initWithResourceManager:self error:NULL];
    }
    return _squareProgram;
}

- (id<MTLBuffer>)squareVertexArray
{
    if (!_squareVertexArray)
    {
        float coords[] = {
            -1.0f, -1.0f,
            1.0f, -1.0f,
            -1.0f, 1.0f,
            1.0f, 1.0f
        };
        _squareVertexArray = [_metalDevice newBufferWithBytes:coords length:sizeof(coords) options:MTLResourceStorageModePrivate];
    }
    return _squareVertexArray;
}

- (GLLProgram *)skeletonProgram
{
    if (!_skeletonProgram) {
        _skeletonProgram = [[GLLSkeletonProgram alloc] initWithResourceManager:self error:NULL];
    }
    return _skeletonProgram;
}

#pragma mark - OpenGL limits

- (NSInteger)maxAnisotropyLevel
{
    return 16; // TODO
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

- (id)_valueForKey:(id)key from:(NSMutableDictionary *)dictionary ifNotFound:(id(^)(void))supplier;
{
    NSParameterAssert(key);
    id result = dictionary[key];
    if (!result)
    {
        result = supplier();
        dictionary[key] = result;
    }
    return result;
    
}

- (NSData *)_dataForFilename:(NSString *)filename error:(NSError *__autoreleasing*)error;
{
    NSString *actualFilename = [[filename componentsSeparatedByString:@"\\"] lastObject];
    
    NSURL *localURL = [NSURL URLWithString:actualFilename relativeToURL:nil];
    NSData *localData = [NSData dataWithContentsOfURL:localURL];
    if (localData) return localData;
    
    NSURL *resourceURL = [NSURL URLWithString:actualFilename relativeToURL:[[NSBundle mainBundle] resourceURL]];
    return [NSData dataWithContentsOfURL:resourceURL options:0 error:error];
}
- (NSString *)_utf8StringForFilename:(NSString *)filename error:(NSError *__autoreleasing*)error;
{
    NSData *data = [self _dataForFilename:filename error:error];
    if (!data) return nil;
    
    return [[NSString alloc] initWithData:data encoding:NSUTF8StringEncoding];
}

@end
