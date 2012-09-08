//
//  GLLResourceManager.m
//  GLLara
//
//  Created by Torsten Kammer on 04.09.12.
//  Copyright (c) 2012 Torsten Kammer. All rights reserved.
//

#import "GLLResourceManager.h"

#import <OpenGL/gl3.h>

#import "GLLModel.h"
#import "GLLModelDrawer.h"
#import "GLLProgram.h"
#import "GLLShader.h"
#import "GLLShaderDescriptor.h"
#import "GLLTexture.h"

@interface GLLResourceManager ()
{
	NSMutableDictionary *shaders;
	NSMutableDictionary *programs;
	NSMutableDictionary *textures;
	NSMutableDictionary *models;
}

- (NSData *)_dataForFilename:(NSString *)filename baseURL:(NSURL *)baseURL;
- (NSString *)_utf8StringForFilename:(NSString *)filename baseURL:(NSURL *)baseURL;

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
	
	shaders = [[NSMutableDictionary alloc] init];
	programs = [[NSMutableDictionary alloc] init];
	textures = [[NSMutableDictionary alloc] init];
	models = [[NSMutableDictionary alloc] init];
	
	return self;
}

- (void)dealloc;
{
	[self.openGLContext makeCurrentContext];
	
	for (GLLModelDrawer *drawer in models.allValues)
		[drawer unload];
	for (GLLTexture *texture in textures.allValues)
		[texture unload];
	for (GLLProgram *program in programs.allValues)
		[program unload];
	for (GLLShader *shader in shaders.allValues)
		[shader unload];
	
	models = nil;
	textures = nil;
	programs = nil;
	shaders = nil;
}

#pragma mark - Retrieving resources

- (GLLModelDrawer *)drawerForModel:(GLLModel *)model error:(NSError *__autoreleasing*)error;
{
	NSAssert(model != nil, @"Empty model passed in. This should never happen.");
	
	id key = model.baseURL;
	id result = [models objectForKey:key];
	if (!result)
	{
		NSOpenGLContext *previous = [NSOpenGLContext currentContext];
		[self.openGLContext makeCurrentContext];
		result = [[GLLModelDrawer alloc] initWithModel:model resourceManager:self error:error];
		[previous makeCurrentContext];
		
		if (!result) return nil;
		[models setObject:result forKey:key];
	}
	return result;
}

- (GLLProgram *)programForDescriptor:(GLLShaderDescriptor *)descriptor error:(NSError *__autoreleasing*)error;
{
	NSAssert(descriptor != nil, @"Empty shader descriptor passed in. This should never happen.");
	
	id result = [programs objectForKey:descriptor.programIdentifier];
	if (!result)
	{
		NSOpenGLContext *previous = [NSOpenGLContext currentContext];
		[self.openGLContext makeCurrentContext];
		result = [[GLLProgram alloc] initWithDescriptor:descriptor resourceManager:self error:error];
		[previous makeCurrentContext];
		
		if (!result) return nil;
		[programs setObject:result forKey:descriptor.programIdentifier];
	}
	return result;
}

- (GLLTexture *)textureForName:(NSString *)textureName baseURL:(NSURL *)baseURL
{
	NSURL *key = [baseURL URLByAppendingPathComponent:textureName];
	id result = [programs objectForKey:key];
	if (!result)
	{
		NSOpenGLContext *previous = [NSOpenGLContext currentContext];
		[self.openGLContext makeCurrentContext];
		result = [[GLLTexture alloc] initWithData:[self _dataForFilename:textureName baseURL:baseURL]];
		[previous makeCurrentContext];
		
		if (!result) return nil;
		[programs setObject:result forKey:key];
	}
	return result;
}

- (GLLShader *)shaderForName:(NSString *)shaderName type:(GLenum)type baseURL:(NSURL *)baseURL error:(NSError *__autoreleasing*)error;
{
	NSAssert(shaderName != nil, @"Empty shader name passed in. This should never happen.");
	
	GLLShader *result = [shaders objectForKey:shaderName];
	if (!result)
	{
		NSOpenGLContext *previous = [NSOpenGLContext currentContext];
		[self.openGLContext makeCurrentContext];
		result = [[GLLShader alloc] initWithSource:[self _utf8StringForFilename:shaderName baseURL:baseURL] name:shaderName type:type error:error];
		[previous makeCurrentContext];
		
		if (!result) return nil;
		[shaders setObject:result forKey:shaderName];
	}
	return result;
}

#pragma mark - Private methods

- (NSData *)_dataForFilename:(NSString *)filename baseURL:(NSURL *)baseURL;
{
	NSString *actualFilename = [[filename componentsSeparatedByString:@"\\"] lastObject];
	
	NSURL *localURL = [NSURL URLWithString:actualFilename relativeToURL:baseURL];
	NSData *localData = [NSData dataWithContentsOfURL:localURL];
	if (localData) return localData;
	
	NSURL *resourceURL = [NSURL URLWithString:actualFilename relativeToURL:[[NSBundle mainBundle] resourceURL]];
	return [NSData dataWithContentsOfURL:resourceURL];
}
- (NSString *)_utf8StringForFilename:(NSString *)filename baseURL:(NSURL *)baseURL;
{
	return [[NSString alloc] initWithData:[self _dataForFilename:filename baseURL:baseURL] encoding:NSUTF8StringEncoding];
}

@end
