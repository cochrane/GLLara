//
//  GLLMesh.m
//  GLLara
//
//  Created by Torsten Kammer on 31.08.12.
//  Copyright (c) 2012 Torsten Kammer. All rights reserved.
//

#import "GLLMesh.h"

#import "GLLModel.h"
#import "TRInDataStream.h"

// There's a very important difference between this Mesh and the one created by XNALara: This one does less work and does not parse the vertex data at all. All target hardware supports enough vertex uniform attributes to allow all 59s bones in the same shader, and there's nothing wrong with storing colors as four bytes.
// That means normalization of bone weights has to be done in the vertex shader, which should not be a big problem.

@implementation GLLMesh

#pragma mark -
#pragma mark Mesh loading

- (id)initFromStream:(TRInDataStream *)stream partOfModel:(GLLModel *)model;
{
	if (!(self = [super init])) return nil;
	
	_model = model;
	
	_name = [stream readPascalString];
	_countOfUVLayers = [stream readUint32];
	
	NSUInteger numTextures = [stream readUint32];
	NSMutableArray *textures = [[NSMutableArray alloc] initWithCapacity:numTextures];
	for (NSUInteger i = 0; i < numTextures; i++)
	{
		NSString *textureName = [stream readPascalString];
		NSUInteger uvLayer = [stream readUint32];
		[textures addObject:@{
			@"name" : textureName,
			@"layer" : @(uvLayer)
		 }];
	}
	_textures = [textures copy];
	
	_countOfVertices = [stream readUint32];
	_vertexData = [stream dataWithLength:_countOfVertices * self.stride];
	
	_countOfElements = 3 * [stream readUint32]; // File saves number of triangles
	_elementData = [stream dataWithLength:_countOfElements * sizeof(uint32_t)];
	
	return self;
}

#pragma mark -
#pragma mark Describe mesh data

- (NSUInteger)offsetForPosition
{
	return 0;
}
- (NSUInteger)offsetForNormal
{
	return 12;
}
- (NSUInteger)offsetForColor
{
	return 24;
}
- (NSUInteger)offsetForTexCoordLayer:(NSUInteger)layer
{
	NSAssert(layer < self.countOfUVLayers, @"Asking for layer %lu but we only have %lu", layer, self.countOfUVLayers);
	
	return 28 + 8*layer;
}
- (NSUInteger)offsetForTangentLayer:(NSUInteger)layer
{
	NSAssert(layer < self.countOfUVLayers, @"Asking for layer %lu but we only have %lu", layer, self.countOfUVLayers);
	
	return 28 + 8*self.countOfUVLayers + 16*layer;
}
- (NSUInteger)offsetForBoneIndices
{
	NSAssert(self.hasBoneWeights, @"Asking for offset for bone indices in mesh that doesn't have any.");
	
	return 28 + 24*self.countOfUVLayers;
}
- (NSUInteger)offsetForBoneWeights
{
	NSAssert(self.hasBoneWeights, @"Asking for offset for bone indices in mesh that doesn't have any.");
	return 28 + 24*self.countOfUVLayers + 8;
}
- (NSUInteger)stride
{
	return 28 + 24*self.countOfUVLayers + (self.hasBoneWeights ? 24 : 0);
}

#pragma mark -
#pragma mark Properties

- (BOOL)hasBoneWeights
{
	return self.model.hasBones;
}

@end
