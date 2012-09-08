//
//  GLLSceneDrawer.m
//  GLLara
//
//  Created by Torsten Kammer on 03.09.12.
//  Copyright (c) 2012 Torsten Kammer. All rights reserved.
//

#import "GLLSceneDrawer.h"

#import <OpenGL/gl3.h>

#import "GLLBoneTransformation.h"
#import "GLLItem.h"
#import "GLLItemDrawer.h"
#import "GLLLight.h"
#import "GLLProgram.h"
#import "GLLResourceManager.h"
#import "GLLUniformBlockBindings.h"
#import "GLLView.h"
#import "simd_matrix.h"
#import "simd_project.h"

static NSString *transformationsKeyPath = @"relativeTransform";

struct GLLLightBlock
{
	vec_float4 cameraLocation;
	struct GLLLightUniformBlock lights[3];
};

struct GLLTransform
{
	mat_float16 viewProjection;
};

struct GLLAlphaTestBlock
{
	GLuint mode;
	GLfloat reference;
};

@interface GLLSceneDrawer ()
{
	NSMutableArray *itemDrawers;
	NSMutableArray *lights;
	id managedObjectContextObserver;
	
	GLuint lightBuffer;
	GLuint transformBuffer;
	GLuint alphaTestBuffer;
	
	mat_float16 lookatMatrix;
	mat_float16 projectionMatrix;
}

- (void)_addDrawerForItem:(GLLItem *)item;
- (void)_unregisterDrawer:(GLLItemDrawer *)drawer;

- (void)_addLight:(GLLLight *)light;
- (void)_unregisterLight:(GLLLight *)light;

@end

@implementation GLLSceneDrawer

- (id)initWithManagedObjectContext:(NSManagedObjectContext *)context view:(GLLView *)view;
{
	if (!(self = [super init])) return nil;

	_managedObjectContext = context;
	_view = view;
	_view.sceneDrawer = self;
	_resourceManager = [[GLLResourceManager alloc] init];
	
	itemDrawers = [[NSMutableArray alloc] init];
	lights = [[NSMutableArray alloc] initWithCapacity:3];
	
	NSEntityDescription *itemEntity = [NSEntityDescription entityForName:@"GLLItem" inManagedObjectContext:self.managedObjectContext];
	NSEntityDescription *lightEntity = [NSEntityDescription entityForName:@"GLLLight" inManagedObjectContext:self.managedObjectContext];
	
	// Set up loading of future items and destroying items. Also update view.
	// Store self as weak in the block, so it does not retain this.
	__block __weak id weakSelf = self;
	managedObjectContextObserver = [[NSNotificationCenter defaultCenter] addObserverForName:NSManagedObjectContextObjectsDidChangeNotification object:_managedObjectContext queue:[NSOperationQueue mainQueue] usingBlock:^(NSNotification *notification) {
		GLLSceneDrawer *self = weakSelf;
		
		// Ensure proper OpenGL context
		[view.openGLContext makeCurrentContext];
		
		NSMutableArray *toRemove = [[NSMutableArray alloc] init];
		for (GLLItemDrawer *drawer in itemDrawers)
		{
			if (![notification.userInfo[NSDeletedObjectsKey] containsObject:drawer.item])
				continue;
			
			[toRemove addObject:drawer];
			[self _unregisterDrawer:drawer];
		}
		[itemDrawers removeObjectsInArray:toRemove];
		
		for (NSManagedObject *deletedItem in notification.userInfo[NSDeletedObjectsKey])
		{
			if ([deletedItem.entity isKindOfEntity:lightEntity])
			{
				[self _unregisterLight:(GLLLight *) deletedItem];
				[lights removeObject:deletedItem];
			}
		}
		
		// New objects includes absolutely anything. Restrict this to items.
		for (NSManagedObject *newItem in notification.userInfo[NSInsertedObjectsKey])
		{
			if ([newItem.entity isKindOfEntity:itemEntity])
				[self _addDrawerForItem:(GLLItem *) newItem];
			else if ([newItem.entity isKindOfEntity:lightEntity])
				[self _addLight:(GLLLight *) newItem];
		}

		view.needsDisplay = YES;
	}];
	
	// Load existing items
	NSFetchRequest *allItemsRequest = [[NSFetchRequest alloc] init];
	allItemsRequest.entity = itemEntity;
	
	NSArray *allItems = [self.managedObjectContext executeFetchRequest:allItemsRequest error:NULL];
	for (GLLItem *item in allItems)
		[self _addDrawerForItem:item];
	
	// Prepare light buffer
	glGenBuffers(1, &lightBuffer);
	glBindBuffer(GL_UNIFORM_BUFFER, lightBuffer);
	struct GLLLightBlock lightBlock;
	bzero(&lightBlock, sizeof(lightBlock));
	lightBlock.cameraLocation = simd_make(0.0, 1.0, 2.0, 1.0);
	lightBlock.lights[0].color = simd_make(1.0, 1.0, 1.0, 0.0);
	lightBlock.lights[0].direction = simd_make(-0.57735, -0.57735, -0.57735, 0.0);
	lightBlock.lights[0].shadowDepth = 0.5;
	lightBlock.lights[0].intensity = 0.5;
	
	glBufferData(GL_UNIFORM_BUFFER, sizeof(lightBlock), &lightBlock, GL_DYNAMIC_DRAW);
	
	// Load existing lights
	NSFetchRequest *allLightsRequest = [[NSFetchRequest alloc] init];
	allLightsRequest.entity = lightEntity;
	NSArray *allLights = [self.managedObjectContext executeFetchRequest:allLightsRequest error:NULL];
	for (GLLLight *light in allLights)
		[self _addLight:light];	
	
	// Set up default lights if there aren't enough.
	[self.managedObjectContext processPendingChanges];
	[self.managedObjectContext.undoManager disableUndoRegistration];
	for (NSUInteger i = allLights.count; i < 3; i++)
	{
		GLLLight *light = [NSEntityDescription insertNewObjectForEntityForName:@"GLLLight" inManagedObjectContext:self.managedObjectContext];
		light.index = i;
		if (i == 0)
		{
			light.isEnabled = YES;
			light.color = [NSColor whiteColor];
			light.intensity = 1.0;
		}
		else
			light.isEnabled = NO;
		[self _addLight:light];
	}
	[self.managedObjectContext processPendingChanges];
	[self.managedObjectContext.undoManager enableUndoRegistration];
	
	// Transform buffer
	glGenBuffers(1, &transformBuffer);
	glBindBuffer(GL_UNIFORM_BUFFER, transformBuffer);
	
	lookatMatrix = simd_mat_lookat(simd_make(0.0, 0.0, -1.0, 0.0), lightBlock.cameraLocation);
	projectionMatrix = simd_frustumMatrix(65.0, 1.0, 0.1, 10.0);
	struct GLLTransform transformBlock;
	transformBlock.viewProjection = simd_mat_mul(projectionMatrix, lookatMatrix);
	
	glBufferData(GL_UNIFORM_BUFFER, sizeof(transformBlock), &transformBlock, GL_STATIC_DRAW);
	
	// Alpha test buffer
	glGenBuffers(1, &alphaTestBuffer);
	glBindBuffer(GL_UNIFORM_BUFFER, alphaTestBuffer);
	struct GLLAlphaTestBlock alphaBlock = { .mode = 0, .reference = 0 };
	glBufferData(GL_UNIFORM_BUFFER, sizeof(alphaBlock), &alphaBlock, GL_DYNAMIC_DRAW);
	
	// Other necessary render state. Thanks to Core Profile, that got cut down a lot.
	glEnable(GL_DEPTH_TEST);
	glEnable(GL_MULTISAMPLE);
	glClearColor(0.2, 0.2, 0.2, 1);
	
	glBlendFunc(GL_SRC_ALPHA, GL_ONE_MINUS_SRC_ALPHA);
	
	[self setWindowSize:view.bounds.size];
	
	self.view.needsDisplay = YES;
	
	return self;
}

- (void)dealloc
{
	[[NSNotificationCenter defaultCenter] removeObserver:managedObjectContextObserver];
	
	for (GLLItemDrawer *drawer in itemDrawers)
		[self _unregisterDrawer:drawer];
}

- (void)observeValueForKeyPath:(NSString *)keyPath ofObject:(id)object change:(NSDictionary *)change context:(void *)context
{
	if ([keyPath isEqual:transformationsKeyPath])
	{
		self.view.needsDisplay = YES;
	}
	else if ([keyPath isEqual:@"dataAsUniformBlock"])
	{
		NSUInteger index = [[object valueForKey:@"index"] unsignedIntegerValue];
		if (index >= 3) return;
		
		[self.view.openGLContext makeCurrentContext];
		
		NSData *value = [object valueForKey:@"dataAsUniformBlock"];
		struct GLLLightUniformBlock block;
		[value getBytes:&block length:sizeof(block)];
		glBindBuffer(GL_UNIFORM_BUFFER, lightBuffer);
		glBufferSubData(GL_UNIFORM_BUFFER, offsetof(struct GLLLightBlock, lights[index]), sizeof(block), &block);
		
		self.view.needsDisplay = YES;
	}
	else
	{
		[super observeValueForKeyPath:keyPath ofObject:object change:change context:context];
	}
}

- (void)unload
{
	[self.resourceManager unload];
}

- (void)setWindowSize:(NSSize)size;
{
	glViewport(0, 0, size.width, size.height);
	
	glBindBuffer(GL_UNIFORM_BUFFER, transformBuffer);
	
	projectionMatrix = simd_frustumMatrix(65.0, size.width / size.height, 0.1, 50.0);
	struct GLLTransform transformBlock;
	transformBlock.viewProjection = simd_mat_mul(projectionMatrix, lookatMatrix);
	
	glBufferData(GL_UNIFORM_BUFFER, sizeof(transformBlock), &transformBlock, GL_STATIC_DRAW);
}

- (void)draw;
{
	glClear(GL_COLOR_BUFFER_BIT | GL_DEPTH_BUFFER_BIT);
	
	glBindBufferBase(GL_UNIFORM_BUFFER, GLLUniformBlockBindingLights, lightBuffer);
	glBindBufferBase(GL_UNIFORM_BUFFER, GLLUniformBlockBindingTransforms, transformBuffer);
	glBindBufferBase(GL_UNIFORM_BUFFER, GLLUniformBlockBindingAlphaTest, alphaTestBuffer);
	
	// 1st pass: Draw items that do not need blending, without alpha test
	glBindBuffer(GL_UNIFORM_BUFFER, alphaTestBuffer);
	struct GLLAlphaTestBlock alphaBlock = { .mode = 0, .reference = 0.9 };
	glBufferData(GL_UNIFORM_BUFFER, sizeof(alphaBlock), &alphaBlock, GL_DYNAMIC_DRAW);
	
	for (GLLItemDrawer *drawer in itemDrawers)
		[drawer drawSolid];
	
	// 2nd pass: Draw blended items, but only those pixels that are "almost opaque"
	alphaBlock.mode = 1;
	glBufferData(GL_UNIFORM_BUFFER, sizeof(alphaBlock), &alphaBlock, GL_DYNAMIC_DRAW);
	
	glEnable(GL_BLEND);
	
	for (GLLItemDrawer *drawer in itemDrawers)
		[drawer drawAlpha];
	
	// 3rd pass: Draw blended items, now only those things that are "mostly transparent".
	alphaBlock.mode = 2;
	glBufferData(GL_UNIFORM_BUFFER, sizeof(alphaBlock), &alphaBlock, GL_DYNAMIC_DRAW);
	
	glDepthMask(GL_FALSE);
	for (GLLItemDrawer *drawer in itemDrawers)
		[drawer drawAlpha];
	
	// Special note: Ensure that depthMask is true before doing the next glClear. Otherwise results may be quite funny indeed.
	glDepthMask(GL_TRUE);
	glDisable(GL_BLEND);
}

#pragma mark - Private methods

- (void)_addDrawerForItem:(GLLItem *)item;
{
	GLLItemDrawer *drawer = [[GLLItemDrawer alloc] initWithItem:item sceneDrawer:self];
	[itemDrawers addObject:drawer];

	for (GLLBoneTransformation *boneTransform in item.boneTransformations)
		[boneTransform addObserver:self forKeyPath:transformationsKeyPath options:0 context:0];
}
- (void)_unregisterDrawer:(GLLItemDrawer *)drawer
{
	for (GLLBoneTransformation *boneTransform in drawer.item.boneTransformations)
		[boneTransform removeObserver:self forKeyPath:transformationsKeyPath];
}

- (void)_addLight:(GLLLight *)light
{
	[lights addObject:light];
	[light addObserver:self forKeyPath:@"dataAsUniformBlock" options:NSKeyValueObservingOptionInitial context:0];
}

- (void)_unregisterLight:(GLLLight *)light
{
	[light removeObserver:self forKeyPath:@"dataAsUniformBlock"];
}

@end
