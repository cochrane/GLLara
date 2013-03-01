//
//  GLLItemMeshTexture+Scripting.m
//  GLLara
//
//  Created by Torsten Kammer on 01.03.13.
//  Copyright (c) 2013 Torsten Kammer. All rights reserved.
//

#import "GLLItemMeshTexture+Scripting.h"

#import "GLLItemMesh+Scripting.h"

@implementation GLLItemMeshTexture (Scripting)

- (NSScriptObjectSpecifier *)objectSpecifier;
{
	return [[NSNameSpecifier alloc] initWithContainerClassDescription:[NSScriptClassDescription classDescriptionForClass:self.mesh.class] containerSpecifier:self.mesh.objectSpecifier key:@"scriptingTextures" name:self.identifier];
}

@end
