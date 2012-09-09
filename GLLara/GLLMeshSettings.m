//
//  GLLMeshSettings.m
//  GLLara
//
//  Created by Torsten Kammer on 05.09.12.
//  Copyright (c) 2012 Torsten Kammer. All rights reserved.
//

#import "GLLMeshSettings.h"

#import "GLLItem.h"
#import "GLLMesh.h"
#import "GLLModel.h"
#import "GLLRenderParameter.h"
#import "GLLShaderDescriptor.h"

@implementation GLLMeshSettings

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
		GLLRenderParameter *parameter = [NSEntityDescription insertNewObjectForEntityForName:@"GLLRenderParameter" inManagedObjectContext:self.managedObjectContext];
		parameter.name = uniformName;
		[parameter setValue:values[uniformName] forKey:@"value"];
		
		[renderParameters addObject:parameter];
	}
}

#pragma mark - Derived

- (NSUInteger)meshIndex
{
	return [self.item.meshSettings indexOfObject:self];
}

- (GLLMesh *)mesh
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
