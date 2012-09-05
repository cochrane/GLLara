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
#import "GLLUniformBlockBindings.h"
#import "GLLProgram.h"
#import "GLLScene.h"
#import "simd_matrix.h"
#import "simd_project.h"

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
	
	// Light buffer
	glGenBuffers(1, &lightBuffer);
	glBindBuffer(GL_UNIFORM_BUFFER, lightBuffer);
	struct GLLLightBlock lightBlock;
	bzero(&lightBlock, sizeof(lightBlock));
	lightBlock.cameraLocation = simd_make(0.0, 0.0, 5.0, 1.0);
	lightBlock.lights[0].color = simd_make(1.0, 1.0, 1.0, 0.0);
	lightBlock.lights[0].direction = simd_make(-0.57735, -0.57735, -0.57735, 0.0);
	lightBlock.lights[0].shadowDepth = 1;
	
	glBufferData(GL_UNIFORM_BUFFER, sizeof(lightBlock), &lightBlock, GL_STATIC_DRAW);
	
	// Transform buffer
	glGenBuffers(1, &transformBuffer);
	glBindBuffer(GL_UNIFORM_BUFFER, transformBuffer);
	
	mat_float16 lookAt = simd_mat_lookat(simd_make(0.0, 0.0, -1.0, 0.0), lightBlock.cameraLocation);
	mat_float16 projection = simd_frustumMatrix(65.0, 1.0, 0.1, 10.0);
	struct GLLTransform transformBlock;
	transformBlock.modelViewProjection = simd_mat_mul(projection, lookAt);
	transformBlock.model = simd_mat_identity();
	
	glBufferData(GL_UNIFORM_BUFFER, sizeof(transformBlock), &transformBlock, GL_STATIC_DRAW);
	
	// Other necessary render state. Thanks to Core Profile, that got cut down a lot.
	glEnable(GL_DEPTH_TEST);
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
	glClear(GL_COLOR_BUFFER_BIT | GL_DEPTH_BUFFER_BIT);
	
	glBindBufferBase(GL_UNIFORM_BUFFER, GLLUniformBlockBindingLights, lightBuffer);
	glBindBufferBase(GL_UNIFORM_BUFFER, GLLUniformBlockBindingTransforms, transformBuffer);
	
	for (GLLItemDrawer *drawer in itemDrawers)
	{
		[drawer drawAlpha];
		[drawer drawNormal];
	}
}

@end
