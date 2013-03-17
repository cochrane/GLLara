//
//  GLLModelMeshV3.m
//  GLLara
//
//  Created by Torsten Kammer on 02.02.13.
//  Copyright (c) 2013 Torsten Kammer. All rights reserved.
//

#import "GLLModelMeshV3.h"

#import "GLLModel.h"
#import "TRInDataStream.h"

@implementation GLLModelMeshV3

- (NSData *)normalizeBoneWeightsInVertices:(NSData *)vertexData
{
	// Add space for tangents
	NSUInteger numVertices = vertexData.length / (self.stride - sizeof(float [4]));
	const float zeroes[4] = { 0.0f, 0.0f, 0.0f, 0.0f };
	
	NSMutableData *data = [NSMutableData dataWithData:vertexData];
	
	for (NSUInteger i = 0; i < numVertices; i++)
	{
		for (NSUInteger layer = 0; layer < self.countOfUVLayers; layer++)
		{
			[data replaceBytesInRange:NSMakeRange([self offsetForTangentLayer:layer] + self.stride*i, 0) withBytes:zeroes length:sizeof(zeroes)];
		}
	}
	
	[self calculateTangents:data];
	return [super normalizeBoneWeightsInVertices:data];
}

- (NSUInteger)rawStride
{
	return self.stride - sizeof(float [4]);
}

@end
