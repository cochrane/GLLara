//
//  GLLMeshSettings.m
//  GLLara
//
//  Created by Torsten Kammer on 05.09.12.
//  Copyright (c) 2012 Torsten Kammer. All rights reserved.
//

#import "GLLMeshSettings.h"

#import "GLLMesh.h"

@implementation GLLMeshSettings

- (id)initWithItem:(GLLItem *)item mesh:(GLLMesh *)mesh;
{
	if (!(self = [super init])) return nil;
	
	_mesh = mesh;
	_isVisible = YES;
	
	return self;
}

- (NSString *)displayName
{
	return self.mesh.name;
}

@end
