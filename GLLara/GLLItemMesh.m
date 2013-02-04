//
//  GLLItemMesh.m
//  GLLara
//
//  Created by Torsten Kammer on 05.09.12.
//  Copyright (c) 2012 Torsten Kammer. All rights reserved.
//

#import "GLLItemMesh.h"

#import <AppKit/NSKeyValueBinding.h>

#import "GLLItem.h"
#import "GLLItemMeshTexture.h"
#import "GLLModel.h"
#import "GLLModelMesh.h"
#import "GLLModelParams.h"
#import "GLLRenderParameter.h"
#import "GLLRenderParameterDescription.h"
#import "GLLShaderDescription.h"
#import "LionSubscripting.h"

@interface GLLItemMesh ()

- (void)_createTextureAssignments;

@end

@implementation GLLItemMesh

+ (NSSet *)keyPathsForValuesAffectingRenderSettings
{
	return [NSSet setWithObjects:@"isVisible", @"cullFaceMode", nil];
}

@dynamic cullFaceMode;
@dynamic isVisible;
@dynamic item;
@dynamic renderParameters;
@dynamic textures;

@dynamic mesh;
@dynamic meshIndex;
@dynamic displayName;

@synthesize renderSettings;

- (void)setItem:(GLLItem *)item
{
	[self willChangeValueForKey:@"item"];
	[self setPrimitiveValue:item forKey:@"item"];
	[self didChangeValueForKey:@"item"];
	
	// Replace all render parameters
	NSDictionary *values = self.mesh.renderParameterValues;
	NSMutableSet *renderParameters = [self mutableSetValueForKey:@"renderParameters"];
	[renderParameters removeAllObjects];
	for (NSString *uniformName in self.mesh.shader.allUniformNames)
	{
		GLLRenderParameterDescription *description = [self.mesh.shader descriptionForParameter:uniformName];

		GLLRenderParameter *parameter;
		
		if ([description.type isEqual:GLLRenderParameterTypeFloat])
			parameter = [NSEntityDescription insertNewObjectForEntityForName:@"GLLFloatRenderParameter" inManagedObjectContext:self.managedObjectContext];
		else if ([description.type isEqual:GLLRenderParameterTypeColor])
			parameter = [NSEntityDescription insertNewObjectForEntityForName:@"GLLColorRenderParameter" inManagedObjectContext:self.managedObjectContext];
		else
			continue; // Skip this param
		
		parameter.name = uniformName;
		[parameter setValue:values[uniformName] forKey:@"value"];
		
		[renderParameters addObject:parameter];
	}
	
	[self _createTextureAssignments];
}

- (void)awakeFromFetch
{
	NSMutableSet *textures = [self mutableSetValueForKey:@"textures"];
	if (textures.count == 0)
		[self _createTextureAssignments];
}

#pragma mark - Derived

- (NSUInteger)meshIndex
{
	return [self.item.meshes indexOfObject:self];
}

- (GLLModelMesh *)mesh
{
	return self.item.model.meshes[self.meshIndex];
}

- (NSString *)displayName
{
	return self.mesh.name;
}

- (GLLRenderParameter *)renderParameterWithName:(NSString *)parameterName;
{
	for (GLLRenderParameter *parameter in self.renderParameters)
	{
		if ([parameter.name isEqual:parameterName])
			return parameter;
	}
	return nil;
}
- (GLLItemMeshTexture *)textureWithIdentifier:(NSString *)textureIdentifier;
{
	for (GLLItemMeshTexture *texture in self.textures)
	{
		if ([texture.identifier isEqual:textureIdentifier])
			return texture;
	}
	return nil;
}

- (id)valueForUndefinedKey:(NSString *)key
{
	GLLRenderParameter *param = [self renderParameterWithName:key];
	if (param) return param;
	
	GLLItemMeshTexture *texture = [self textureWithIdentifier:key];
	if (texture) return texture;
	
	return NSNotApplicableMarker;
}

#pragma mark - Private

- (void)_createTextureAssignments;
{	
	// Replace all textures
	NSMutableSet *textures = [self mutableSetValueForKey:@"textures"];
	[textures removeAllObjects];
	for (NSUInteger i = 0; i < self.mesh.shader.textureUniformNames.count; i++)
	{
		GLLItemMeshTexture *texture = [NSEntityDescription insertNewObjectForEntityForName:@"GLLItemMeshTexture" inManagedObjectContext:self.managedObjectContext];
		texture.mesh = self;
		texture.identifier = self.mesh.shader.textureUniformNames[i];
		texture.textureURL = self.mesh.textures[i];
	}
}

@end
