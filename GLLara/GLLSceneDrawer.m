//
//  GLLSceneDrawer.m
//  GLLara
//
//  Created by Torsten Kammer on 03.09.12.
//  Copyright (c) 2012 Torsten Kammer. All rights reserved.
//

#import "GLLSceneDrawer.h"

#import <OpenGL/gl3.h>

#import "GLLItemDrawer.h"
#import "GLLScene.h"
#import "GLLResourceManager.h"
#import "simd_matrix.h"

struct GLLLight
{
	vec_float4 color;
	vec_float4 direction;
	float intensity;
	float shadowDepth;
};

struct GLLLightBlock
{
	vec_float4 cameraLocation;
	struct GLLLight lights[3];
};

struct GLLTransform
{
	mat_float16 modelViewProjection;
	mat_float16 model;
};

@interface GLLSceneDrawer ()
{
	NSMutableArray *itemDrawers;
	GLuint lightBuffer;
	GLuint transformBuffer;
}

@end

@implementation GLLSceneDrawer

- (id)initWithScene:(GLLScene *)scene resourceManager:(GLLResourceManager *)resourceManager;
{
	if (!(self = [super init])) return nil;

	_scene = scene;
	_resourceManager = resourceManager;
	
	itemDrawers = [[NSMutableArray alloc] init];
	
	return self;
}

- (void)setResourceManager:(GLLResourceManager *)resourceManager
{
	NSAssert(_resourceManager == nil, @"don't set the resource manager twice!");
	
	_resourceManager = resourceManager;
	[_scene addObserver:self forKeyPath:@"items" options:NSKeyValueObservingOptionInitial | NSKeyValueObservingOptionNew | NSKeyValueObservingOptionOld context:NULL];
	
	glClearColor(0.2, 0.2, 0.2, 1);
}

- (void)dealloc
{
	[_scene removeObserver:self forKeyPath:@"items"];
}

- (void)observeValueForKeyPath:(NSString *)keyPath ofObject:(id)object change:(NSDictionary *)change context:(void *)context
{
	if ([keyPath isEqual:@"items"])
	{
		NSMutableArray *toRemove = [[NSMutableArray alloc] init];
		for (GLLItemDrawer *drawer in itemDrawers)
		{
			if ([change[NSKeyValueChangeOldKey] containsObject:drawer.item])
				[toRemove addObject:drawer];
		}
		[itemDrawers removeObjectsInArray:toRemove];
		
		for (GLLItem *newItem in change[NSKeyValueChangeNewKey])
		{
			[itemDrawers addObject:[[GLLItemDrawer alloc] initWithItem:newItem sceneDrawer:self]];
		}
	}
	else
		[super observeValueForKeyPath:keyPath ofObject:object change:change context:context];
}

- (void)setWindowSize:(NSSize)size;
{
	glViewport(0, 0, size.width, size.height);
}

- (void)draw;
{
	for (GLLItemDrawer *drawer in itemDrawers)
	{
		[drawer drawAlpha];
		[drawer drawNormal];
	}
	
	glClear(GL_COLOR_BUFFER_BIT | GL_DEPTH_BUFFER_BIT);
}

@end
