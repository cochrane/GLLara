//
//  GLLItemMesh+Scripting.m
//  GLLara
//
//  Created by Torsten Kammer on 01.03.13.
//  Copyright (c) 2013 Torsten Kammer. All rights reserved.
//

#import "GLLItemMesh+Scripting.h"

#import "GLLItem+Scripting.h"

@implementation GLLItemMesh (Scripting)

- (NSScriptObjectSpecifier *)objectSpecifier;
{
	return [[NSNameSpecifier alloc] initWithContainerClassDescription:[NSScriptClassDescription classDescriptionForClass:self.item.class] containerSpecifier:self.item.objectSpecifier key:@"scriptingMeshes" name:self.displayName];
}

- (NSArray *)scriptingTextures;
{
	return [self.textures sortedArrayUsingDescriptors:@[ [NSSortDescriptor sortDescriptorWithKey:@"identifier" ascending:YES] ]];
}
- (NSArray *)scriptingRenderParameters;
{
	return [self.renderParameters sortedArrayUsingDescriptors:@[ [NSSortDescriptor sortDescriptorWithKey:@"name" ascending:YES] ]];
}

@end
