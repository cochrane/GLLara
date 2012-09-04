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
#import "GLLShaderList.h"
#import "GLLTexture.h"

@interface GLLResourceManager ()
{
	NSMutableDictionary *shaders;
	NSMutableDictionary *programs;
	NSMutableDictionary *textures;
	NSMutableDictionary *models;
}

- (GLLShader *)_shaderForName:(NSString *)shaderName type:(GLenum)type baseURL:(NSURL *)baseURL;
- (NSData *)_dataForFilename:(NSString *)filename baseURL:(NSURL *)baseURL;
- (NSString *)_utf8StringForFilename:(NSString *)filename baseURL:(NSURL *)baseURL;

@end

@implementation GLLResourceManager

- (id)init
{
	if (!(self = [super init])) return nil;
	
	shaders = [[NSMutableDictionary alloc] init];
	programs = [[NSMutableDictionary alloc] init];
	textures = [[NSMutableDictionary alloc] init];
	models = [[NSMutableDictionary alloc] init];
	
	return self;
}

#pragma mark -
#pragma mark Retrieving resources

- (GLLModelDrawer *)drawerForModel:(GLLModel *)model;
{
	id key = model.baseURL;
	id result = [models objectForKey:key];
	if (!result)
	{
		result = [[GLLModelDrawer alloc] initWithModel:model resourceManager:self];
		[models setObject:result forKey:key];
	}
	return result;
}

- (GLLProgram *)programForName:(NSString *)programName baseURL:(NSURL *)baseURL
{
	if (!programName) return nil;
	
	id result = [programs objectForKey:programName];
	if (!result)
	{
		NSString *vertexName = [[GLLShaderList defaultShaderList] vertexShaderForName:programName];
		NSString *geometryName = [[GLLShaderList defaultShaderList] geometryShaderForName:programName];
		NSString *fragmentName = [[GLLShaderList defaultShaderList] fragmentShaderForName:programName];
		
		result = [[GLLProgram alloc] initWithVertexShader:[self _shaderForName:vertexName type:GL_VERTEX_SHADER baseURL:baseURL] geometryShader:[self _shaderForName:geometryName type:GL_GEOMETRY_SHADER baseURL:baseURL] fragmentShader:[self _shaderForName:fragmentName type:GL_FRAGMENT_SHADER baseURL:baseURL]];
		[programs setObject:result forKey:programName];
	}
	return result;
}

- (GLLTexture *)textureForName:(NSString *)textureName baseURL:(NSURL *)baseURL
{
	NSURL *key = [NSURL URLWithString:textureName relativeToURL:baseURL];
	id result = [programs objectForKey:key];
	if (!result)
	{
		result = [[GLLTexture alloc] initWithData:[self _dataForFilename:textureName baseURL:baseURL]];
		[programs setObject:result forKey:key];
	}
	return result;
}

- (NSArray *)texturesForNames:(NSArray *)textureNames baseURL:(NSURL *)baseURL
{
	NSMutableArray *result = [[NSMutableArray alloc] initWithCapacity:textureNames.count];
	for (NSString *name in textureNames)
		[result addObject:[self textureForName:name baseURL:baseURL]];
	return [result copy];
}

#pragma mark -
#pragma mark Private methods

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

- (GLLShader *)_shaderForName:(NSString *)shaderName type:(GLenum)type baseURL:(NSURL *)baseURL;
{
	if (!shaderName) return nil;
	
	GLLShader *result = [shaders objectForKey:shaderName];
	if (!result)
	{
		result = [[GLLShader alloc] initWithSource:[self _utf8StringForFilename:shaderName baseURL:baseURL] type:type];
		[shaders setObject:result forKey:shaderName];
	}
	return result;
}

@end
