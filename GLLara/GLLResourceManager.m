//
//  GLLResourceManager.m
//  GLLara
//
//  Created by Torsten Kammer on 04.09.12.
//  Copyright (c) 2012 Torsten Kammer. All rights reserved.
//

#import "GLLResourceManager.h"

#import "GLLModel.h"
#import "GLLPreferenceKeys.h"
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
    NSMutableDictionary<NSString *, GLLPipelineStateInformation*> *pipelines;
    NSMutableDictionary<NSString *, id<MTLFunction>> *functions;
}

- (NSData *)_dataForFilename:(NSString *)filename error:(NSError *__autoreleasing*)error;
- (NSString *)_utf8StringForFilename:(NSString *)filename error:(NSError *__autoreleasing*)error;
- (id)_valueForKey:(id)key from:(NSMutableDictionary *)dictionary ifNotFound:(id(^)(void))supplier;
- (id<MTLFunction>)_functionForName:(NSString *)name shader:(GLLShaderData*)shader error:(NSError *__autoreleasing*)error;
- (void)_recreateSampler;

@end

static GLLResourceManager *sharedManager;

@implementation GLLResourceManager

+ (GLLResourceManager *)sharedResourceManager
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
    _depthPixelFormat = MTLPixelFormatDepth32Float;
    
    [self _recreateSampler];
    
    MTLDepthStencilDescriptor *depthDescriptor = [[MTLDepthStencilDescriptor alloc] init];
    depthDescriptor.depthCompareFunction = MTLCompareFunctionLessEqual;
    depthDescriptor.depthWriteEnabled = YES;
    _normalDepthStencilState = [_metalDevice newDepthStencilStateWithDescriptor:depthDescriptor];
    
    // Alpha test buffers
    struct GLLAlphaTestBlock alphaBlock = { .mode = 1, .reference = .9 };
    _alphaTestPassGreaterBuffer = [_metalDevice newBufferWithBytes:&alphaBlock length:sizeof(alphaBlock) options:MTLResourceStorageModeManaged];
    _alphaTestPassGreaterBuffer.label = @"alpha-test-pass-greater";
    
    struct GLLAlphaTestBlock alphaBlockPassLess = { .mode = 2, .reference = .9 };
    _alphaTestPassLessBuffer = [_metalDevice newBufferWithBytes:&alphaBlockPassLess length:sizeof(alphaBlock) options:MTLResourceStorageModeManaged];
    _alphaTestPassLessBuffer.label = @"alpha-test-pass-less";
    
    [[NSUserDefaultsController sharedUserDefaultsController] addObserver:self forKeyPath:[@"values." stringByAppendingString:GLLPrefAnisotropyAmount] options:NSKeyValueObservingOptionNew context:0];
    [[NSUserDefaultsController sharedUserDefaultsController] addObserver:self forKeyPath:[@"values." stringByAppendingString:GLLPrefUseAnisotropy] options:NSKeyValueObservingOptionNew context:0];
    
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
        return [[GLLModelDrawData alloc] initWithModel:model resourceManager:self];
    }];
}

/*- (GLLModelProgram *)programForDescriptor:(GLLShaderData *)description error:(NSError *__autoreleasing*)error;
{
    NSParameterAssert(description);
    
    return [self _valueForKey:description from:programs ifNotFound:^{
        return [[GLLModelProgram alloc] initWithDescriptor:description resourceManager:self error:error];
    }];
}*/

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
        return [[GLLTexture alloc] initWithURL:effectiveURL device:self.metalDevice error:error];
    }];
}

/*- (GLLShader *)shaderForName:(NSString *)shaderName additionalDefines:(NSDictionary *)defines usedTexCoords:(NSIndexSet *)texCoords type:(GLenum)type error:(NSError *__autoreleasing*)error;
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
}*/

- (GLLPipelineStateInformation *)pipelineForVertex:(GLLVertexAttribAccessorSet *)vertexDescriptor shader:(GLLShaderData *)shader error:(NSError *__autoreleasing*)error; {
    NSParameterAssert(vertexDescriptor);
    NSParameterAssert(shader);
    
    // TODO Does this work?
    NSDictionary *key = @{
        @"shader": shader,
        @"vertexDescriptor": vertexDescriptor.vertexDescriptor
    };
    
    return [self _valueForKey:key from:pipelines ifNotFound:(id)^{
        id<MTLFunction> vertexFunction = [self _functionForName:shader.vertexName shader:shader error:error];
        if (!vertexFunction) {
            return (id)nil;
        }
        
        id<MTLFunction> fragmentFunction = [self _functionForName:shader.fragmentName shader:shader error:error];
        if (!fragmentFunction) {
            return (id)nil;
        }
        
        MTLRenderPipelineDescriptor *descriptor = [[MTLRenderPipelineDescriptor alloc] init];
        descriptor.vertexFunction = vertexFunction;
        descriptor.fragmentFunction = fragmentFunction;
        descriptor.colorAttachments[0].pixelFormat = self.pixelFormat;
        descriptor.depthAttachmentPixelFormat = self.depthPixelFormat;
        descriptor.vertexDescriptor = vertexDescriptor.vertexDescriptor;
        
        id<MTLRenderPipelineState> renderPipelineState = [self.metalDevice newRenderPipelineStateWithDescriptor:descriptor error:error];
        if (!renderPipelineState) {
            return (id)nil;
        }
        
        GLLPipelineStateInformation *information = [[GLLPipelineStateInformation alloc] init];
        information.vertexProgram = vertexFunction;
        information.fragmentProgram = fragmentFunction;
        information.pipelineState = renderPipelineState;
        return (id)information;
    }];
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
        _squareVertexArray.label = @"square-vertex";
    }
    return _squareVertexArray;
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

-(void)observeValueForKeyPath:(NSString *)keyPath ofObject:(id)object change:(NSDictionary<NSKeyValueChangeKey,id> *)change context:(void *)context {
    if (object == [NSUserDefaultsController sharedUserDefaultsController]) {
        [self _recreateSampler];
    } else {
        [super observeValueForKeyPath:keyPath ofObject:object change:change context:context];
    }
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

- (id<MTLFunction>)_functionForName:(NSString *)name shader:(GLLShaderData*)shader error:(NSError *__autoreleasing*)error {
    NSParameterAssert(name);
    NSParameterAssert(shader);
    
    NSDictionary *key = @{
        @"name": name,
        @"shader": shader
    };
    
    return [self _valueForKey:key from:pipelines ifNotFound:(id)^{
        MTLFunctionConstantValues *values = [[MTLFunctionConstantValues alloc] init];
        bool *valuesArray = calloc(sizeof(bool), GLLFunctionConstantBoolMax);
        NSIndexSet *setParameters = shader.activeBoolConstants;
        for (NSUInteger i = 0; i < GLLFunctionConstantBoolMax; i++) {
            if ([setParameters containsIndex:i]) {
                valuesArray[i] = true;
            }
        }
        [values setConstantValues:valuesArray type:MTLDataTypeBool withRange:NSMakeRange(0, GLLFunctionConstantBoolMax)];
        //free(valuesArray);
        
        // TODO Make this dependent on what is actually going on in the scene
        int oneLight = 1;
        [values setConstantValue:&oneLight type:MTLDataTypeInt atIndex:GLLFunctionConstantNumberOfUsedLights];
        
        return [self.library newFunctionWithName:name constantValues:values error:error];
    }];
}

- (void)_recreateSampler {
    MTLSamplerDescriptor *samplerDescriptor = [[MTLSamplerDescriptor alloc] init];
    samplerDescriptor.minFilter = MTLSamplerMinMagFilterLinear;
    samplerDescriptor.magFilter = MTLSamplerMinMagFilterLinear;
    samplerDescriptor.mipFilter = MTLSamplerMipFilterLinear;
    samplerDescriptor.rAddressMode = MTLSamplerAddressModeRepeat;
    samplerDescriptor.sAddressMode = MTLSamplerAddressModeRepeat;
    samplerDescriptor.tAddressMode = MTLSamplerAddressModeRepeat;
    samplerDescriptor.supportArgumentBuffers = YES;
    
    BOOL useAnisotropy = [[NSUserDefaults standardUserDefaults] boolForKey:GLLPrefUseAnisotropy];
    NSInteger anisotropyAmount = [[NSUserDefaults standardUserDefaults] integerForKey:GLLPrefAnisotropyAmount];
    samplerDescriptor.maxAnisotropy = useAnisotropy ? anisotropyAmount : 0;
    
    _metalSampler = [_metalDevice newSamplerStateWithDescriptor:samplerDescriptor];
}

@end
