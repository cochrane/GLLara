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
#import "GLLModelProgram.h"
#import "GLLShader.h"
#import "GLLShaderDescription.h"
#import "GLLSquareProgram.h"
#import "GLLTexture.h"

@interface GLLResourceManager ()
{
	NSMutableDictionary *shaders;
	NSMutableDictionary *programs;
	NSMutableDictionary *textures;
	NSMutableDictionary *models;
}

- (NSData *)_dataForFilename:(NSString *)filename baseURL:(NSURL *)baseURL error:(NSError *__autoreleasing*)error;
- (NSString *)_utf8StringForFilename:(NSString *)filename baseURL:(NSURL *)baseURL error:(NSError *__autoreleasing*)error;

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
	for (GLLModelProgram *program in programs.allValues)
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

- (GLLModelProgram *)programForDescriptor:(GLLShaderDescription *)description error:(NSError *__autoreleasing*)error;
{
	NSAssert(description != nil, @"Empty shader descriptor passed in. This should never happen.");
	
	id result = [programs objectForKey:description.programIdentifier];
	if (!result)
	{
		NSOpenGLContext *previous = [NSOpenGLContext currentContext];
		[self.openGLContext makeCurrentContext];
		result = [[GLLModelProgram alloc] initWithDescriptor:description resourceManager:self error:error];
		[previous makeCurrentContext];
		
		if (!result) return nil;
		[programs setObject:result forKey:description.programIdentifier];
	}
	return result;
}

- (GLLTexture *)textureForURL:(NSURL *)textureURL error:(NSError *__autoreleasing*)error;
{
	id result = [textures objectForKey:textureURL];
	if (!result)
	{
		NSData *textureData = [NSData dataWithContentsOfURL:textureURL options:NSDataReadingUncached error:error];
		if (!textureData)
		{
			// Second attempt: Maybe there is a default version of that in the bundle.
			// If not, then keep error from first read.
			NSURL *resourceURL = [[NSBundle mainBundle] URLForResource:textureURL.lastPathComponent withExtension:nil];
			if (!resourceURL)
				return nil;
		}
		
		NSOpenGLContext *previous = [NSOpenGLContext currentContext];
		[self.openGLContext makeCurrentContext];
		result = [[GLLTexture alloc] initWithData:textureData];
		[previous makeCurrentContext];
		
		if (!result) return nil;
		[textures setObject:result forKey:textureURL];
	}
	return result;
}

- (GLLShader *)shaderForName:(NSString *)shaderName type:(GLenum)type baseURL:(NSURL *)baseURL error:(NSError *__autoreleasing*)error;
{
	NSAssert(shaderName != nil, @"Empty shader name passed in. This should never happen.");
	
	GLLShader *result = [shaders objectForKey:shaderName];
	if (!result)
	{
		NSString *shaderSource = [self _utf8StringForFilename:shaderName baseURL:baseURL error:error];
		if (!shaderSource) return nil;
		
		// Actual loading
		NSOpenGLContext *previous = [NSOpenGLContext currentContext];
		[self.openGLContext makeCurrentContext];
		result = [[GLLShader alloc] initWithSource:shaderSource name:shaderName type:type error:error];
		[previous makeCurrentContext];
		
		if (!result) return nil;
		[shaders setObject:result forKey:shaderName];
	}
	return result;
}

- (GLLProgram *)squareProgram
{
	if (!_squareProgram)
	{
		NSError *error = nil;
		
		NSOpenGLContext *previous = [NSOpenGLContext currentContext];
		[self.openGLContext makeCurrentContext];
		_squareProgram = [[GLLSquareProgram alloc] initWithResourceManager:self error:&error];
		[previous makeCurrentContext];
		
		NSAssert(_squareProgram, @"Could not load square program because of %@", error);
	}
	return _squareProgram;
}

- (GLuint)squareVertexArray
{
	if (!_squareVertexArray)
	{
		NSOpenGLContext *previous = [NSOpenGLContext currentContext];
		[self.openGLContext makeCurrentContext];
		
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
		
		[previous makeCurrentContext];
	}
	return _squareVertexArray;
}

#pragma mark - Private methods

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
