//
//  GLLItem+OBJExport.m
//  GLLara
//
//  Created by Torsten Kammer on 19.09.12.
//  Copyright (c) 2012 Torsten Kammer. All rights reserved.
//

#import "GLLItem+OBJExport.h"

#import "NSArray+Map.h"
#import "GLLItemBone.h"
#import "GLLItemMesh+OBJExport.h"
#import "GLLModelBone.h"
#import "GLLModelMesh.h"

@implementation GLLItem (OBJExport)

- (BOOL)willLoseDataWhenConvertedToOBJ
{
	for (GLLItemMesh *mesh in self.meshes)
		if (mesh.willLoseDataWhenConvertedToOBJ)
			return YES;
	
	return NO;
}

- (NSString *)objStringForFilename:(NSString *)name withTransform:(BOOL)transform withColor:(BOOL)color error:(NSError *__autoreleasing*)error;
{
	NSMutableString *obj = [NSMutableString string];
	
	NSString *materialLibraryName = [[name stringByDeletingPathExtension] stringByAppendingPathExtension:@"mtl"];
	[obj appendFormat:@"mtllib %@\n", materialLibraryName];
	
	mat_float16 *transforms = malloc(sizeof(mat_float16) * self.bones.count);
	NSUInteger boneIndex = 0;
	for (GLLItemBone *bone in self.bones)
	{
		if (transform)
			[bone.globalTransform getValue:&transforms[boneIndex]];
		else
			transforms[boneIndex] = bone.bone.positionMatrix;
		boneIndex += 1;
	}
	
	uint32_t indexOffset = 0;
	for (GLLItemMesh *mesh in self.meshes)
	{
		[obj appendString:[mesh writeOBJWithTransformations:transforms baseIndex:indexOffset includeColors:color]];
		indexOffset += mesh.mesh.countOfVertices;
	}
	
	free(transforms);

	return obj;
}
- (NSString *)mtlStringForLocation:(NSURL *)location error:(NSError *__autoreleasing*)error;
{
	return [[self.meshes map:^(GLLItemMesh *mesh) {
		return [mesh writeMTLWithBaseURL:location];
	}] componentsJoinedByString:@"\n"];
}

- (BOOL)writeOBJToLocation:(NSURL *)location withTransform:(BOOL)transform withColor:(BOOL)color error:(NSError *__autoreleasing*)error;
{
	return [[self objStringForFilename:location.lastPathComponent withTransform:transform withColor:color error:error] writeToURL:location atomically:YES encoding:NSUTF8StringEncoding error:error];
}

- (BOOL)writeMTLToLocation:(NSURL *)location error:(NSError *__autoreleasing*)error;
{
	return [[self mtlStringForLocation:location error:error] writeToURL:location atomically:YES encoding:NSUTF8StringEncoding error:error];
}

@end
