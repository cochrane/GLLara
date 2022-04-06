//
//  GLLModelMesh+OBJExport.m
//  GLLara
//
//  Created by Torsten Kammer on 19.09.12.
//  Copyright (c) 2012 Torsten Kammer. All rights reserved.
//

#import "GLLModelMesh+OBJExport.h"

#import "GLLVertexAttribAccessor.h"
#import "GLLVertexAttribAccessorSet.h"
#import "GLLVertexFormat.h"

#import "simd_matrix.h"

@implementation GLLModelMesh (OBJExport)

- (NSString *)writeOBJWithTransformations:(const mat_float16 *)transforms baseIndex:(uint32_t)baseIndex includeColors:(BOOL)includeColors;
{
    NSMutableString *objString = [[NSMutableString alloc] init];
    
    [objString appendFormat:@"g %@\n", [[self.name componentsSeparatedByCharactersInSet:[NSCharacterSet whitespaceAndNewlineCharacterSet]] componentsJoinedByString:@"_"]];
    [objString appendFormat:@"usemtl material%lu\n", self.meshIndex];
    
    GLLVertexAttribAccessor *positionAccessor = [self.vertexDataAccessors accessorForSemantic:GLLVertexAttribPosition];
    GLLVertexAttribAccessor *normalAccessor = [self.vertexDataAccessors accessorForSemantic:GLLVertexAttribPosition];
    GLLVertexAttribAccessor *texCoordAccessor = [self.vertexDataAccessors accessorForSemantic:GLLVertexAttribTexCoord0 layer:0];
    GLLVertexAttribAccessor *colorAccessor = [self.vertexDataAccessors accessorForSemantic:GLLVertexAttribColor layer:0];
    GLLVertexAttribAccessor *boneIndexAccessor = [self.vertexDataAccessors accessorForSemantic:GLLVertexAttribBoneIndices];
    GLLVertexAttribAccessor *boneWeightAccessor = [self.vertexDataAccessors accessorForSemantic:GLLVertexAttribBoneWeights];
    
    for (NSInteger i = 0; i < self.countOfVertices; i++)
    {
        const float *position = [positionAccessor elementAt:i];
        const float *normal = [normalAccessor elementAt:i];
        
        mat_float16 transform = transforms[0];
        if (boneIndexAccessor)
        {
            const uint16_t *boneIndices = [boneIndexAccessor elementAt:i];
            const float *boneWeights = [boneWeightAccessor elementAt:i];
            
            transform = simd_mat_scale(transforms[boneIndices[0]], boneWeights[0]);
            transform = simd_mat_add(transform, simd_mat_scale(transforms[boneIndices[1]], boneWeights[1]));
            transform = simd_mat_add(transform, simd_mat_scale(transforms[boneIndices[2]], boneWeights[2]));
            transform = simd_mat_add(transform, simd_mat_scale(transforms[boneIndices[3]], boneWeights[3]));
        }
        
        vec_float4 transformedPosition = simd_mat_vecmul(transform, simd_make(position[0], position[1], position[2], 1.0f));
        vec_float4 transformedNormal = simd_mat_vecrotate(transform, simd_make(normal[0], normal[1], normal[2], 0.0f));
        
        [objString appendFormat:@"v %f %f %f\n", simd_extract(transformedPosition, 0), simd_extract(transformedPosition, 1), simd_extract(transformedPosition, 2)];
        [objString appendFormat:@"vn %f %f %f\n", simd_extract(transformedNormal, 0), simd_extract(transformedNormal, 1), simd_extract(transformedNormal, 2)];
        
        const float *texCoords = [texCoordAccessor elementAt:i];
        [objString appendFormat:@"vt %f %f\n", texCoords[0], 1.0 - texCoords[1]]; // Turn tex coords around (because I don't want to swap the whole image)
        
        if (includeColors)
        {
            const uint8_t *color = [colorAccessor elementAt:i];
            [objString appendFormat:@"vc %f %f %f %f\n", (float) color[0] / 255.0f, (float) color[1] / 255.0f, (float) color[2] / 255.0f, (float) color[3] / 255.0f];
        }
    }
    
    for (NSInteger i = 0; i < self.countOfUsedElements; i += 3)
    {
        NSUInteger adjustedElements[3] = {
            [self elementAt:i + 0] + baseIndex + 1,
            [self elementAt:i + 2] + baseIndex + 1,
            [self elementAt:i + 1] + baseIndex + 1
        };
        
        if (includeColors)
            [objString appendFormat:@"f %1$lu/%1$lu/%1$lu/%1$lu %2$lu/%2$lu/%2$lu/%2$lu %3$lu/%3$lu/%3$lu/%3$lu\n", adjustedElements[0], adjustedElements[1], adjustedElements[2]];
        else
            [objString appendFormat:@"f %1$lu/%1$lu/%1$lu %2$lu/%2$lu/%2$lu %3$lu/%3$lu/%3$lu\n", adjustedElements[0], adjustedElements[1], adjustedElements[2]];
    }
    
    return [objString copy];
}

@end
