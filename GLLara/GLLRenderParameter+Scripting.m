//
//  GLLRenderParameter+Scripting.m
//  GLLara
//
//  Created by Torsten Kammer on 01.03.13.
//  Copyright (c) 2013 Torsten Kammer. All rights reserved.
//

#import "GLLRenderParameter+Scripting.h"

#import "GLLItemMesh+Scripting.h"

@implementation GLLRenderParameter (Scripting)

- (NSScriptObjectSpecifier *)objectSpecifier;
{
	return [[NSNameSpecifier alloc] initWithContainerClassDescription:[NSScriptClassDescription classDescriptionForClass:self.mesh.class] containerSpecifier:self.mesh.objectSpecifier key:@"scriptingTextures" name:self.name];
}

@end
