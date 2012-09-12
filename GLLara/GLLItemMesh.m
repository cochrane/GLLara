//
//  GLLItemMesh.m
//  GLLara
//
//  Created by Torsten Kammer on 05.09.12.
//  Copyright (c) 2012 Torsten Kammer. All rights reserved.
//

#import "GLLItemMesh.h"

#import "GLLItem.h"
#import "GLLModel.h"
#import "GLLModelMesh.h"
#import "GLLModelParams.h"
#import "GLLRenderParameter.h"
#import "GLLRenderParameterDescription.h"
#import "GLLShaderDescription.h"

@implementation GLLItemMesh

+ (NSSet *)keyPathsForValuesAffectingRenderSettings
{
	return [NSSet setWithObjects:@"isVisible", @"cullFaceMode", nil];
}

@dynamic cullFaceMode;
@dynamic isVisible;
@dynamic item;
@dynamic renderParameters;

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
	NSDictionary *values = self.mesh.renderParameters;
	NSMutableSet *renderParameters = [self mutableSetValueForKey:@"renderParameters"];
	[renderParameters removeAllObjects];
	for (NSString *uniformName in self.mesh.shader.allUniformNames)
	{
		GLLRenderParameterDescription *description = [self.item descriptionForParameter:uniformName];

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

#pragma mark - Source list item

- (BOOL)isSourceListHeader
{
	return NO;
}
- (NSString *)sourceListDisplayName
{
	return self.mesh.name;
}
- (BOOL)hasChildrenInSourceList
{
	return NO;
}
- (NSUInteger)numberOfChildrenInSourceList
{
	return 0;
}
- (id)childInSourceListAtIndex:(NSUInteger)index;
{
	return nil;
}

@end
