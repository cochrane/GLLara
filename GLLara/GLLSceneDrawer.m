//
//  GLLSceneDrawer.m
//  GLLara
//
//  Created by Torsten Kammer on 03.09.12.
//  Copyright (c) 2012 Torsten Kammer. All rights reserved.
//

#import "GLLSceneDrawer.h"

#import <OpenGL/gl3.h>

#import "GLLItem.h"
#import "GLLBoneTransformation.h"
#import "GLLItemDrawer.h"
#import "GLLProgram.h"
#import "GLLResourceManager.h"
#import "GLLUniformBlockBindings.h"
#import "GLLView.h"
#import "simd_matrix.h"
#import "simd_project.h"

static NSString *transformationsKeyPath = @"relativeTransform";

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
	mat_float16 viewProjection;
};

@interface GLLSceneDrawer ()
{
	NSMutableArray *itemDrawers;
	id managedObjectContextObserver;
	
	GLuint lightBuffer;
	GLuint transformBuffer;
	
	mat_float16 lookatMatrix;
	mat_float16 projectionMatrix;
}

- (void)_addDrawerForItem:(GLLItem *)item;
- (void)_unregisterDrawer:(GLLItemDrawer *)drawer;

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
		
		// New objects includes absolutely anything. Restrict this to items.
		for (NSManagedObject *newItem in notification.userInfo[NSInsertedObjectsKey])
		{
			if ([newItem.entity isKindOfEntity:[NSEntityDescription entityForName:@"GLLItem" inManagedObjectContext:self.managedObjectContext]])
				[self _addDrawerForItem:(GLLItem *) newItem];
		}

		view.needsDisplay = YES;
	}];
	
	// Load existing items
	NSFetchRequest *allItemsRequest = [[NSFetchRequest alloc] init];
	allItemsRequest.entity = [NSEntityDescription entityForName:@"GLLItem" inManagedObjectContext:self.managedObjectContext];
	allItemsRequest.includesSubentities = YES;
	allItemsRequest.includesPendingChanges = YES;
	
	NSArray *allItems = [self.managedObjectContext executeFetchRequest:allItemsRequest error:NULL];
	for (GLLItem *item in allItems)
		[self _addDrawerForItem:item];
	
	// Light buffer
	glGenBuffers(1, &lightBuffer);
	glBindBuffer(GL_UNIFORM_BUFFER, lightBuffer);
	struct GLLLightBlock lightBlock;
	bzero(&lightBlock, sizeof(lightBlock));
	lightBlock.cameraLocation = simd_make(0.0, 1.0, 2.0, 1.0);
	lightBlock.lights[0].color = simd_make(1.0, 1.0, 1.0, 0.0);
	lightBlock.lights[0].direction = simd_make(-0.57735, -0.57735, -0.57735, 0.0);
	lightBlock.lights[0].shadowDepth = 0.5;
	lightBlock.lights[0].intensity = 0.5;
	
	glBufferData(GL_UNIFORM_BUFFER, sizeof(lightBlock), &lightBlock, GL_STATIC_DRAW);
	
	// Transform buffer
	glGenBuffers(1, &transformBuffer);
	glBindBuffer(GL_UNIFORM_BUFFER, transformBuffer);
	
	lookatMatrix = simd_mat_lookat(simd_make(0.0, 0.0, -1.0, 0.0), lightBlock.cameraLocation);
	projectionMatrix = simd_frustumMatrix(65.0, 1.0, 0.1, 10.0);
	struct GLLTransform transformBlock;
	transformBlock.viewProjection = simd_mat_mul(projectionMatrix, lookatMatrix);
	
	glBufferData(GL_UNIFORM_BUFFER, sizeof(transformBlock), &transformBlock, GL_STATIC_DRAW);
	
	// Other necessary render state. Thanks to Core Profile, that got cut down a lot.
	glEnable(GL_DEPTH_TEST);
	glEnable(GL_MULTISAMPLE);
	glClearColor(0.2, 0.2, 0.2, 1);
	
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
	
	projectionMatrix = simd_frustumMatrix(65.0, size.width / size.height, 0.1, 10.0);
	struct GLLTransform transformBlock;
	transformBlock.viewProjection = simd_mat_mul(projectionMatrix, lookatMatrix);
	
	glBufferData(GL_UNIFORM_BUFFER, sizeof(transformBlock), &transformBlock, GL_STATIC_DRAW);
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

@end
