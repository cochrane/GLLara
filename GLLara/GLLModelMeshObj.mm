//
//  GLLModelMeshObj.m
//  GLLara
//
//  Created by Torsten Kammer on 12.09.12.
//  Copyright (c) 2012 Torsten Kammer. All rights reserved.
//

#import "GLLModelMeshObj.h"

#import <AppKit/NSColor.h>

#import "GLLModelParams.h"

@implementation GLLModelMeshObj

- (id)initWithObjFile:(GLLObjFile *)file range:(const GLLObjFile::MaterialRange &)range inModel:(GLLModel *)model error:(NSError *__autoreleasing*)error;
{
	if (!(self = [super initAsPartOfModel:model])) return nil;
	
	// Procedure: Go through the indices in the range. For each index, load the vertex data from the file and put it in the vertex buffer here. Adjust the index, too.
	
	self.countOfUVLayers = 1;
	
	if (range.material == 0)
	{
		if (error)
			*error = [NSError errorWithDomain:@"GLLMeshObj" code:1 userInfo:@{ NSLocalizedDescriptionKey : NSLocalizedString(@"Some parts of the model have no material", @"error description: material for range is null"),
	   NSLocalizedRecoverySuggestionErrorKey : NSLocalizedString(@"This model is not supported.", @"error description: material for range is null") }];
		return nil;
	}
	
	std::map<unsigned, uint32_t> globalToLocalVertices;
	NSMutableData *vertices = [[NSMutableData alloc] init];
	NSMutableData *elements = [[NSMutableData alloc] initWithCapacity:sizeof(uint32_t) * (range.end - range.start)];
	
	for (unsigned i = range.start; i < range.end; i++)
	{
		unsigned globalIndex = file->getIndices().at(i);
		uint32_t index = 0;
		auto localIndexIter = globalToLocalVertices.find(globalIndex);
		if (localIndexIter == globalToLocalVertices.end())
		{
			// Add adjusted element
			index = (uint32_t) globalToLocalVertices.size();
			globalToLocalVertices[globalIndex] = index;
			
			// Add vertex
			const GLLObjFile::VertexData &vertex = file->getVertexData().at(globalIndex);
			
			[vertices appendBytes:vertex.vert length:sizeof(float [3])];
			[vertices appendBytes:vertex.norm length:sizeof(float [3])];
			[vertices appendBytes:vertex.color length:sizeof(uint8_t [4])];
			float texCoordY = 1.0f - vertex.tex[1]; // Turn tex coords around (because I don't want to swap the whole image)
			[vertices appendBytes:vertex.tex length:sizeof(float)];
			[vertices appendBytes:&texCoordY length:sizeof(float)];
			
			// Space for tangents
			float zero[4] = { 0, 0, 0, 0 };
			[vertices appendBytes:&zero length:sizeof(zero)];
			
			// No bone weights or indices here; OBJs use special shaders that don't use them.
		}
		else
			index = localIndexIter->second;
		
		// Add to element buffer
		[elements appendBytes:&index length:sizeof(index)];
	}
	
	// Necessary postprocessing
	[self calculateTangents:vertices];
	
	// Set up other attributes
	self.vertexData = [vertices copy];
	self.elementData = [elements copy];
	self.countOfVertices = globalToLocalVertices.size();
	self.countOfElements = range.end - range.start;
	
	// Setup material
	// Three options: Diffuse, DiffuseSpecular, DiffuseNormal, DiffuseSpecularNormal
	GLLModelParams *objModelParams = [GLLModelParams parametersForName:@"objFileParameters" error:error];
	if (!objModelParams)
		return nil;
	
	if (range.material->specularTexture == NULL && range.material->normalTexture == NULL)
	{
		if (range.material->diffuseTexture != NULL)
		{
			self.textures = @[ (__bridge NSURL *) range.material->diffuseTexture ];
			self.shader = [objModelParams shaderNamed:@"DiffuseOBJ"];
		}
		else
		{
			self.textures = @[];
			self.shader = [objModelParams shaderNamed:@"TexturelessOBJ"];
		}
	}
	else if (range.material->specularTexture != NULL && range.material->normalTexture == NULL)
	{
		self.textures = @[ (__bridge NSURL *) range.material->diffuseTexture, (__bridge NSURL *) range.material->specularTexture ];
		self.shader = [objModelParams shaderNamed:@"DiffuseSpecularOBJ"];
	}
	else if (range.material->specularTexture == NULL && range.material->normalTexture != NULL)
	{
		self.textures = @[ (__bridge NSURL *) range.material->diffuseTexture, (__bridge NSURL *) range.material->normalTexture ];
		self.shader = [objModelParams shaderNamed:@"DiffuseNormalOBJ"];
	}
	else if (range.material->specularTexture != NULL && range.material->normalTexture != NULL)
	{
		self.textures = @[ (__bridge NSURL *) range.material->diffuseTexture, (__bridge NSURL *) range.material->specularTexture, (__bridge NSURL *) range.material->normalTexture ];
		self.shader = [objModelParams shaderNamed:@"DiffuseSpecularNormalOBJ"];
	}
	self.renderParameterValues = @{ @"ambientColor" : [NSColor colorWithCalibratedRed:range.material->ambient[0] green:range.material->ambient[1] blue:range.material->ambient[2] alpha:range.material->ambient[3]],
	@"diffuseColor" : [NSColor colorWithCalibratedRed:range.material->diffuse[0] green:range.material->diffuse[1] blue:range.material->diffuse[2] alpha:range.material->diffuse[3]],
	@"specularColor" : [NSColor colorWithCalibratedRed:range.material->specular[0] green:range.material->specular[1] blue:range.material->specular[2] alpha:range.material->specular[3]],
	@"specularExponent": @(range.material->shininess)
	};
	
	// Always use blending, since I can't prove that it doesn't otherwise.
	self.usesAlphaBlending = YES;
	
	return self;
}

- (BOOL)hasBoneWeights
{
	return NO; // OBJ files don't use them. They do use one bone matrix, for the model position, but that's it.
}

- (GLLCullFaceMode)cullFaceMode
{
	return GLLCullClockWise;
}

@end
