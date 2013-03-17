//
//  GLLModelMesh+OBJExport.m
//  GLLara
//
//  Created by Torsten Kammer on 19.09.12.
//  Copyright (c) 2012 Torsten Kammer. All rights reserved.
//

#import "GLLModelMesh+OBJExport.h"

#import "simd_matrix.h"

@implementation GLLModelMesh (OBJExport)

- (NSString *)writeOBJWithTransformations:(const mat_float16 *)transforms baseIndex:(uint32_t)baseIndex includeColors:(BOOL)includeColors;
{
	NSMutableString *objString = [[NSMutableString alloc] init];
	
	NSData *vertexData = [self staticVertexDataWithTransforms:transforms];
	NSUInteger staticStride = vertexData.length / self.countOfVertices;
	
	[objString appendFormat:@"g %@\n", [[self.name componentsSeparatedByCharactersInSet:[NSCharacterSet whitespaceAndNewlineCharacterSet]] componentsJoinedByString:@"_"]];
	[objString appendFormat:@"usemtl material%lu\n", self.meshIndex];
	
	for (NSUInteger i = 0; i < self.countOfVertices; i++)
	{
		const float *position = vertexData.bytes + staticStride*i + self.offsetForPosition;
		const float *normal = vertexData.bytes + staticStride*i + self.offsetForNormal;

		[objString appendFormat:@"v %f %f %f\n", position[0], position[1], position[2]];
		[objString appendFormat:@"vn %f %f %f\n", normal[0], normal[1], normal[2]];
		
		const float *texCoords = (const float *) (vertexData.bytes + staticStride*i + [self offsetForTexCoordLayer:0]);
		[objString appendFormat:@"vt %f %f\n", texCoords[0], 1.0 - texCoords[1]]; // Turn tex coords around (because I don't want to swap the whole image)
		
		if (includeColors)
		{
			const uint8_t *color = vertexData.bytes + staticStride*i + self.offsetForColor;
			[objString appendFormat:@"vc %f %f %f %f\n", (float) color[0] / 255.0f, (float) color[1] / 255.0f, (float) color[2] / 255.0f, (float) color[3] / 255.0f];
		}
	}
	
	for (NSUInteger i = 0; i < self.countOfElements; i += 3)
	{
		const uint32_t *elements = self.elementData.bytes + i*sizeof(uint32_t);
		uint32_t adjustedElements[3] = {
			elements[0] + baseIndex + 1,
			elements[2] + baseIndex + 1,
			elements[1] + baseIndex + 1
		};
		
		if (includeColors)
			[objString appendFormat:@"f %1$u/%1$u/%1$u/%1$u %2$u/%2$u/%2$u/%2$u %3$u/%3$u/%3$u/%3$u\n", adjustedElements[0], adjustedElements[1], adjustedElements[2]];
		else
			[objString appendFormat:@"f %1$u/%1$u/%1$u %2$u/%2$u/%2$u %3$u/%3$u/%3$u\n", adjustedElements[0], adjustedElements[1], adjustedElements[2]];
	}
	
	return [objString copy];
}

@end
