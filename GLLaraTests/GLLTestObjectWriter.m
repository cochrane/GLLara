//
//  GLLTestObjectWriter.m
//  GLLara
//
//  Created by Torsten Kammer on 07.03.13.
//  Copyright (c) 2013 Torsten Kammer. All rights reserved.
//

#import "GLLTestObjectWriter.h"

enum quadPosition
{
	LowerLeft,
	LowerRight,
	UpperRight,
	UpperLeft
};
enum quadDirection
{
	XPlus,
	XMinus,
	YPlus,
	YMinus,
	ZPlus,
	ZMinus
};

@interface GLLTestObjectWriter ()
{
	NSMutableArray *meshes;
}

- (NSString *)_vertexAt:(enum quadPosition)position direction:(enum quadDirection)direction quadCenter:(const float *)center bonesLowX:(const uint16_t *)bonesLowX bonesHighX:(const uint16_t *)bonesHighX numTexCoords:(NSUInteger)numTexCoords;
- (NSString *)_quadWithDirection:(enum quadDirection)direction cubeCenter:(const float *)center bonesLowX:(const uint16_t *)bonesLowX bonesHighX:(const uint16_t *)bonesHighX numTexCoords:(NSUInteger)numTexCoords;

@end

@implementation GLLTestObjectWriter

- (id)init
{
	if (!(self = [super init])) return nil;
	
	return self;
}

- (void)setNumMeshes:(NSUInteger)numMeshes
{
	_numMeshes = numMeshes;
	meshes = [NSMutableArray arrayWithCapacity:numMeshes];
	for (NSUInteger i = 0; i < numMeshes; i++)
		[meshes addObject:[NSMutableDictionary dictionaryWithDictionary:@{
						   @"textures" : [NSMutableArray array],
						   @"name" : @"",
						   @"layers" : @(0) }]];
}

- (void)setNumUVLayers:(NSUInteger)layers forMesh:(NSUInteger)mesh;
{
	meshes[mesh][@"layers"] = @(layers);
}

- (void)addTextureFilename:(NSString *)name uvLayer:(NSUInteger)layer toMesh:(NSUInteger)mesh
{
	[meshes[mesh][@"textures"] addObject:@{ @"name" : name, @"layer" : @(layer) }];
}

- (void)setRenderGroup:(NSUInteger)group renderParameterValues:(NSArray *)values forMesh:(NSUInteger)mesh;
{
	NSMutableString *name = [NSMutableString stringWithFormat:@"%lu_mesh%lu", group, mesh];
	for (id value in values)
		[name appendFormat:@"_%@", value];
	meshes[mesh][@"name"] = name;
}

- (NSString *)testFileString
{
	NSMutableString *result = [NSMutableString string];
	
	// Write bones
	[result appendFormat:@"%lu\n", self.numBones];
	for (NSUInteger i = 0; i < self.numBones; i++)
	{
		[result appendFormat:@"bone%lu\n", i];
		[result appendFormat:@"%d\n", (i > 0) ? 0 : -1];
		[result appendFormat:@"%f %f %f\n", (CGFloat) i, 0.0, 0.0];

	}
	
	// Write meshes
	[result appendFormat:@"%lu\n", self.numMeshes];
	for (NSInteger i = 0; i < (NSInteger) self.numMeshes; i++)
	{
		NSDictionary *description = meshes[i];
		NSUInteger numTexCoords = [description[@"layers"] unsignedIntegerValue];
		[result appendFormat:@"%@\n%lu\n%lu\n", description[@"name"], numTexCoords, [description[@"textures"] count]];
		for (NSDictionary *texture in description[@"textures"])
			[result appendFormat:@"%@\n%@\n", texture[@"name"], texture[@"layer"]];

		BOOL mustWriteStartCap = (i == 0);
		BOOL mustWriteEndCap = (i == (NSInteger) self.numMeshes - 1);
		NSUInteger sectionsToWrite = 1;
		if (mustWriteEndCap && self.numMeshes < self.numBones)
			sectionsToWrite = 1 + self.numBones - self.numMeshes;
		
		NSUInteger numVertices = sectionsToWrite * 4 * 4 + (mustWriteEndCap ? 4 : 0) + (mustWriteStartCap ? 4 : 0);
		[result appendFormat:@"%lu\n", numVertices];
		
		
		if (mustWriteStartCap)
			[result appendString:[self _quadWithDirection:XMinus cubeCenter:(float [3]) { 0.0f, 0.0f, 0.0f } bonesLowX:(const uint16_t [4]) { 0, 0, 0, 0 } bonesHighX:NULL numTexCoords:numTexCoords]];
		
		for (NSInteger j = 0; j < (NSInteger) sectionsToWrite; j++)
		{
			// Find bone indices.
			NSInteger thisBone = MAX(MIN(i+j, (NSInteger) self.numBones-1), 0);
			NSInteger prevBone = MAX(MIN(i+j-1, (NSInteger) self.numBones-1), 0);
			NSInteger nextBone = MAX(MIN(i+j+1, (NSInteger) self.numBones-1), 0);
			
			// Find values to write
			uint16_t bonesLowX[4] = { thisBone, prevBone, 0, 0 };
			uint16_t bonesHighX[4] = { thisBone, nextBone, 0, 0 };
			float cubeCenter[3] = { (float)(i+j), 0.0f, 0.0f };
			
			// Write
			[result appendString:[self _quadWithDirection:ZPlus
											   cubeCenter:cubeCenter
												bonesLowX:bonesLowX
											   bonesHighX:bonesHighX
											 numTexCoords:numTexCoords]];
			[result appendString:[self _quadWithDirection:YPlus
											   cubeCenter:cubeCenter
												bonesLowX:bonesLowX
											   bonesHighX:bonesHighX
											 numTexCoords:numTexCoords]];
			[result appendString:[self _quadWithDirection:ZMinus
											   cubeCenter:cubeCenter
												bonesLowX:bonesLowX
											   bonesHighX:bonesHighX
											 numTexCoords:numTexCoords]];
			[result appendString:[self _quadWithDirection:YMinus
											   cubeCenter:cubeCenter
												bonesLowX:bonesLowX
											   bonesHighX:bonesHighX
											 numTexCoords:numTexCoords]];
		}
		
		if (mustWriteEndCap)
			[result appendString:[self _quadWithDirection:XPlus cubeCenter:(float [3]) { (float)(i+sectionsToWrite-1), 0.0f, 0.0f } bonesLowX:(const uint16_t [4]) { self.numBones-1, 0, 0, 0 } bonesHighX:NULL numTexCoords:numTexCoords]];
		
		// Write elements
		[result appendFormat:@"%lu\n", numVertices/2]; // 4 vertices -> 2 triangles
		for (NSUInteger j = 0; j < (numVertices/4); j++)
		{
			[result appendFormat:@"%lu %lu %lu\t", j*4 + 0, j*4 + 1, j*4 + 2];
			[result appendFormat:@"%lu %lu %lu\n", j*4 + 2, j*4 + 3, j*4 + 0];
		}
	}
	
	return [result copy];
}

#pragma mark - Private methods

- (NSString *)_quadWithDirection:(enum quadDirection)direction cubeCenter:(const float *)center bonesLowX:(const uint16_t *)bonesLowX bonesHighX:(const uint16_t *)bonesHighX numTexCoords:(NSUInteger)numTexCoords;
{
	NSMutableString *result = [NSMutableString string];
	
	for (NSUInteger i = 0; i < 4; i++)
		[result appendString:[self _vertexAt:(enum quadPosition)i direction:direction quadCenter:center bonesLowX:bonesLowX bonesHighX:bonesHighX numTexCoords:numTexCoords]];
	
	return [result copy];
}

- (NSString *)_vertexAt:(enum quadPosition)position direction:(enum quadDirection)direction quadCenter:(const float *)center bonesLowX:(const uint16_t *)bonesLowX bonesHighX:(const uint16_t *)bonesHighX numTexCoords:(NSUInteger)numTexCoords;
{
	float pos[3] = { center[0], center[1], center[2] };
	float x[3] = { 0.0f, 0.0f, 0.0f };
	float y[3] = { 0.0f, 0.0f, 0.0f };
	float z[3] = { 0.0f, 0.0f, 0.0f }; // Normal
	
	switch(direction)
	{
		case XPlus:
			x[2] = -1.0;
			y[1] = -1.0;
			z[0] = 1.0;
			break;
		case XMinus:
			x[2] = 1.0;
			y[1] = -1.0;
			z[0] = -1.0;
			break;
		case YPlus:
			x[0] = 1.0;
			y[2] = 1.0;
			z[1] = 1.0;
			break;
		case YMinus:
			x[0] = -1.0;
			y[2] = 1.0;
			z[1] = -1.0;
			break;
		case ZPlus:
			x[0] = -1.0;
			y[1] = 1.0;
			z[2] = 1.0;
			break;
		case ZMinus:
			x[0] = -1.0;
			y[1] = -1.0;
			z[2] = -1.0;
			break;
		default:
			return nil;
	}
	
	float texCoords[2] = { 0.0f, 0.0f };
	switch (position)
	{
		case LowerLeft:
			pos[0] += 0.5f * (-x[0] + -y[0] + z[0]);
			pos[1] += 0.5f * (-x[1] + -y[1] + z[1]);
			pos[2] += 0.5f * (-x[2] + -y[2] + z[2]);
			break;
		case LowerRight:
			pos[0] += 0.5f * (x[0] + -y[0] + z[0]);
			pos[1] += 0.5f * (x[1] + -y[1] + z[1]);
			pos[2] += 0.5f * (x[2] + -y[2] + z[2]);
			texCoords[0] = 1.0f;
			break;
		case UpperLeft:
			pos[0] += 0.5f * (-x[0] + y[0] + z[0]);
			pos[1] += 0.5f * (-x[1] + y[1] + z[1]);
			pos[2] += 0.5f * (-x[2] + y[2] + z[2]);
			texCoords[1] = 1.0f;
			break;
		case UpperRight:
			pos[0] += 0.5f * (x[0] + y[0] + z[0]);
			pos[1] += 0.5f * (x[1] + y[1] + z[1]);
			pos[2] += 0.5f * (x[2] + y[2] + z[2]);
			texCoords[0] = 1.0f;
			texCoords[1] = 1.0f;
			break;
		default:
			return nil;
	}
	
	// Find bone indices
	const uint16_t *boneIndices;
	if (bonesHighX == 0)
		boneIndices = bonesLowX;
	else if (pos[0] < (center[0] - 0.01f))
		boneIndices = bonesLowX;
	else
		boneIndices = bonesHighX;
	
	float boneWeights[4] = { 1.0f, 0.0f, 0.0f, 0.0f };
	if (boneIndices[0] != boneIndices[1])
		boneWeights[0] = boneWeights[1] = 0.5f;
	
	// Write it all out
	NSMutableString *result = [NSMutableString string];
	[result appendFormat:@"%f %f %f\n", pos[0], pos[1], pos[2]];
	[result appendFormat:@"%f %f %f\n", z[0], z[1], z[2]];
	[result appendString:@"255 255 255 255\n"];
	for (NSUInteger i = 0; i < numTexCoords; i++)
		[result appendFormat:@"%f %f\n", texCoords[0]*(i+1), texCoords[1]*(i+1)];
	[result appendFormat:@"%u %u %u %u\n", boneIndices[0], boneIndices[1], boneIndices[2], boneIndices[3]];
	[result appendFormat:@"%f %f %f %f\n", boneWeights[0], boneWeights[1], boneWeights[2], boneWeights[3]];
	
	return [result copy];
}

@end
