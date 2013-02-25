//
//  GLLItemMesh+MeshExport.m
//  GLLara
//
//  Created by Torsten Kammer on 25.02.13.
//  Copyright (c) 2013 Torsten Kammer. All rights reserved.
//

#import "GLLItemMesh+MeshExport.h"

#import "GLLItemMeshTexture.h"
#import "GLLFloatRenderParameter.h"
#import "GLLModelMesh.h"
#import "GLLShaderDescription.h"
#import "NSArray+Map.h"

@implementation GLLItemMesh (MeshExport)

- (NSString *)genericItemName
{
	NSMutableString *genericItemName = [NSMutableString string];
	
	// 1 - get mesh group
	NSSet *possibleGroups = self.mesh.usesAlphaBlending ? self.shader.alphaMeshGroups : self.shader.solidMeshGroups;
	NSRegularExpression *meshGroupNameRegexp = [NSRegularExpression regularExpressionWithPattern:@"^MeshGroup([0-9]+)$" options:0 error:NULL];
	for (NSString *groupName in possibleGroups)
	{
		NSTextCheckingResult *match = [meshGroupNameRegexp firstMatchInString:groupName options:NSMatchingAnchored range:NSMakeRange(0, groupName.length)];
		if (match.range.location == NSNotFound) continue;
		
		[genericItemName appendString:[groupName substringWithRange:[match rangeAtIndex:1]]];
		[genericItemName appendString:@"_"];
		break;
	}
	NSAssert(genericItemName.length > 0, @"Did not find group for mesh %@ with shader name %@", self.displayName, self.shaderName);
	
	// 2 - add display name, removing all underscores and newlines
	NSCharacterSet *illegalSet = [NSCharacterSet characterSetWithCharactersInString:@"\n\r_"];
	[genericItemName appendString:[[self.displayName componentsSeparatedByCharactersInSet:illegalSet] componentsJoinedByString:@"-"]];
	
	// 3 - write required parameters
	for (NSString *renderParameterName in self.shader.parameterUniformNames)
	{
		GLLFloatRenderParameter *param = (GLLFloatRenderParameter *) [self renderParameterWithName:renderParameterName];
		NSAssert(param && [param isMemberOfClass:[GLLFloatRenderParameter class]], @"Objects with shader %@ have to have parameter %@ and it must be float", self.shaderName, renderParameterName);
		
		[genericItemName appendFormat:@"_%f", param.value];
	}
	
	return genericItemName;
}

- (NSArray *)textureURLsInShaderOrder
{
	return [self.shader.textureUniformNames map:^(NSString *textureName){
		return [self textureWithIdentifier:textureName].textureURL;
	}];
}

- (NSString *)writeASCII;
{
	return [self.mesh writeASCIIWithName:self.genericItemName texture:self.textureURLsInShaderOrder];
}
- (NSData *)writeBinary;
{
	return [self.mesh writeBinaryWithName:self.genericItemName texture:self.textureURLsInShaderOrder];
}

@end
