//
//  GLLItemMesh+OBJExport.m
//  GLLara
//
//  Created by Torsten Kammer on 19.09.12.
//  Copyright (c) 2012 Torsten Kammer. All rights reserved.
//

#import "GLLItemMesh+OBJExport.h"

#import "GLLModelMesh+OBJExport.h"
#import "LionSubscripting.h"

@implementation GLLItemMesh (OBJExport)

- (BOOL)willLoseDataWhenConvertedToOBJ
{
	if (self.mesh.textures.count > 1) return YES;
	if (self.renderParameters.count > 0) return YES;
	
	return NO;
}

- (NSString *)writeMTLWithBaseURL:(NSURL *)baseURL;
{
	NSMutableString *mtlString = [[NSMutableString alloc] init];
	
	[mtlString appendFormat:@"newmtl material%lu\n", self.meshIndex];
	
	// Use only first texture
	if (self.mesh.textures.count > 0)
	{
		NSArray *baseComponents = baseURL.pathComponents;
		NSArray *textureComponents = [self.mesh.textures[0] pathComponents];
		
		NSMutableArray *relativePathComponents = [NSMutableArray array];
		
		// Find where the paths diverge
		NSUInteger firstDifference;
		for (firstDifference = 0; firstDifference < MIN(baseComponents.count, textureComponents.count); firstDifference++)
			if (![baseComponents[firstDifference] isEqual:textureComponents[firstDifference]]) break;
		
		// Add .. for any additional path in the base file
		for (NSUInteger i = firstDifference; i < baseComponents.count - 1; i++)
			[relativePathComponents addObject:@".."];
		
		// Add rest of path to the texture
		[relativePathComponents addObjectsFromArray:[textureComponents subarrayWithRange:NSMakeRange(firstDifference, textureComponents.count - firstDifference)]];
		
		NSString *texturePath = [relativePathComponents componentsJoinedByString:@"/"];
		
		[mtlString appendFormat:@"map_Kd %@\n", texturePath];
	}
	
	return [mtlString copy];
}

- (NSString *)writeOBJWithTransformations:(const mat_float16 *)transforms baseIndex:(uint32_t)baseIndex includeColors:(BOOL)includeColors;
{
	return [self.mesh writeOBJWithTransformations:transforms baseIndex:baseIndex includeColors:includeColors];
}

@end
