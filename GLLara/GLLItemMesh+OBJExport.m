//
//  GLLItemMesh+OBJExport.m
//  GLLara
//
//  Created by Torsten Kammer on 19.09.12.
//  Copyright (c) 2012 Torsten Kammer. All rights reserved.
//

#import "GLLItemMesh+OBJExport.h"

#import <AppKit/NSColorSpace.h>

#import "GLLColorRenderParameter.h"
#import "GLLFloatRenderParameter.h"
#import "GLLItemMeshTexture.h"
#import "GLLModelMesh+OBJExport.h"

@implementation GLLItemMesh (OBJExport)

+ (NSString *)relativePathFrom:(NSURL *)ownLocation to:(NSURL *)textureLocation;
{
	if (!ownLocation)
		return textureLocation.lastPathComponent;
	
	NSArray *baseComponents = ownLocation.pathComponents;
	NSArray *textureComponents = [textureLocation pathComponents];
	
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

	return texturePath;
}

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
	
	GLLItemMeshTexture *diffuse = [self textureWithIdentifier:@"diffuseTexture"];
	if (diffuse)
	{
		[mtlString appendFormat:@"map_Kd %@\n", [[self class] relativePathFrom:baseURL to:diffuse.textureURL]];
	}
	
	GLLItemMeshTexture *specular = [self textureWithIdentifier:@"specularTexture"];
	if (specular)
	{
		[mtlString appendFormat:@"map_Ks %@\n", [[self class] relativePathFrom:baseURL to:specular.textureURL]];
	}
	
	GLLItemMeshTexture *bump = [self textureWithIdentifier:@"bumpTexture"];
	if (bump)
	{
		[mtlString appendFormat:@"bump %@\n", [[self class] relativePathFrom:baseURL to:bump.textureURL]];
	}
	
	GLLColorRenderParameter *diffuseColor = (GLLColorRenderParameter *) [self renderParameterWithName:@"diffuseColor"];
	if (diffuseColor)
	{
		CGFloat r,g,b,a;
		[[diffuseColor.value colorUsingColorSpace:[NSColorSpace genericRGBColorSpace]] getRed:&r green:&g blue:&b alpha:&a];
		[mtlString appendFormat:@"Kd %f %f %f %f\n", r, g, b, a];
	}
	
	GLLColorRenderParameter *specularColor = (GLLColorRenderParameter *) [self renderParameterWithName:@"specularColor"];
	if (specularColor)
	{
		CGFloat r,g,b,a;
		[[specularColor.value colorUsingColorSpace:[NSColorSpace genericRGBColorSpace]] getRed:&r green:&g blue:&b alpha:&a];
		[mtlString appendFormat:@"Ks %f %f %f %f\n", r, g, b, a];
	}
	
	GLLColorRenderParameter *ambientColor = (GLLColorRenderParameter *) [self renderParameterWithName:@"ambientColor"];
	if (ambientColor)
	{
		CGFloat r,g,b,a;
		[[ambientColor.value colorUsingColorSpace:[NSColorSpace genericRGBColorSpace]] getRed:&r green:&g blue:&b alpha:&a];
		[mtlString appendFormat:@"Ka %f %f %f %f\n", r, g, b, a];
	}
	
	GLLFloatRenderParameter *specularExponent = (GLLFloatRenderParameter *) [self renderParameterWithName:@"specularExponent"];
	GLLFloatRenderParameter *bumpSpecularGloss = (GLLFloatRenderParameter *) [self renderParameterWithName:@"bumpSpecularGloss"];
	if (specularExponent)
		[mtlString appendFormat:@"Ns %f\n", specularExponent.value];
	else if (bumpSpecularGloss)
		[mtlString appendFormat:@"Ns %f\n", bumpSpecularGloss.value];
	
	return [mtlString copy];
}

- (NSString *)writeOBJWithTransformations:(const mat_float16 *)transforms baseIndex:(uint32_t)baseIndex includeColors:(BOOL)includeColors;
{
	return [self.mesh writeOBJWithTransformations:transforms baseIndex:baseIndex includeColors:includeColors];
}

@end
