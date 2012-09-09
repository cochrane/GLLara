//
//  GLLTransformedMeshDrawer.m
//  GLLara
//
//  Created by Torsten Kammer on 06.09.12.
//  Copyright (c) 2012 Torsten Kammer. All rights reserved.
//

#import "GLLTransformedMeshDrawer.h"

#import <OpenGL/gl3.h>

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
	
	switch (self.settings.cullFaceMode)
	{
		case GLLCullBack:
			glCullFace(GL_BACK);
			break;
			
		case GLLCullFront:
			glCullFace(GL_FRONT);
			break;
			
		case GLLCullNone:
			glDisable(GL_CULL_FACE);
			
		default:
			break;
	}
	
	[self.drawer drawWithTransforms:transforms];
	
	// Enable it again.
	if (self.settings.cullFaceMode == GLLCullNone)
		glEnable(GL_CULL_FACE);
}

@end
