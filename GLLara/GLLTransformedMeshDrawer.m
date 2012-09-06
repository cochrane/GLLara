//
//  GLLTransformedMeshDrawer.m
//  GLLara
//
//  Created by Torsten Kammer on 06.09.12.
//  Copyright (c) 2012 Torsten Kammer. All rights reserved.
//

#import "GLLTransformedMeshDrawer.h"

#import "GLLMeshDrawer.h"
#import "GLLMeshSettings.h"

@implementation GLLTransformedMeshDrawer

- (id)initWithDrawer:(GLLMeshDrawer *)drawer settings:(GLLMeshSettings *)settings;
{
	if (!(self = [super init])) return nil;
	
	NSAssert(drawer != nil && settings != nil, @"Have to have drawer and settings.");
	
	_drawer = drawer;
	_settings = settings;
	
	return self;
}

- (void)drawWithTransforms:(const mat_float16 *)transforms;
{
	if (!self.settings.isVisible)
		return;
	
	[self.drawer drawWithTransforms:transforms];
}

@end
