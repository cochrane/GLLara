//
//  GLLSceneDrawer.m
//  GLLara
//
//  Created by Torsten Kammer on 03.09.12.
//  Copyright (c) 2012 Torsten Kammer. All rights reserved.
//

#import "GLLSceneDrawer.h"

#import <AppKit/NSColorSpace.h>
#import <OpenGL/gl3.h>

#import "GLLAmbientLight.h"
#import "GLLBoneTransformation.h"
#import "GLLCamera.h"
#import "GLLDirectionalLight.h"
#import "GLLItem.h"
#import "GLLItemDrawer.h"
#import "GLLMeshSettings.h"
#import "GLLProgram.h"
#import "GLLRenderParameter.h"
#import "GLLResourceManager.h"
#import "GLLUniformBlockBindings.h"
#import "GLLView.h"
#import "simd_matrix.h"
#import "simd_project.h"

struct GLLLightBlock
{
	vec_float4 cameraLocation;
	vec_float4 ambientColor;
	struct GLLLightUniformBlock lights[3];
};

struct GLLAlphaTestBlock
{
	GLuint mode;
	GLfloat reference;
};

@interface GLLSceneDrawer ()
{
	NSMutableArray *itemDrawers;
	NSArray *lights; // Always one ambient and three directional ones. Don't watch for mutations.
	id managedObjectContextObserver;
	
	GLuint lightBuffer;
	GLuint transformBuffer;
	
	// Alpha test
	GLuint alphaTestDisabledBuffer;
	GLuint alphaTestPassGreaterBuffer;
	GLuint alphaTestPassLessBuffer;
	
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
	_resourceManager = [GLLResourceManager sharedResourceManager];
	
	itemDrawers = [[NSMutableArray alloc] init];
	lights = [[NSMutableArray alloc] initWithCapacity:4];
	
	NSEntityDescription *itemEntity = [NSEntityDescription entityForName:@"GLLItem" inManagedObjectContext:self.managedObjectContext];
	
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
			if ([newItem.entity isKindOfEntity:itemEntity])
				[self _addDrawerForItem:(GLLItem *) newItem];
		}

		view.needsDisplay = YES;
	}];
	
	// Load existing items
	NSFetchRequest *allItemsRequest = [[NSFetchRequest alloc] init];
	allItemsRequest.entity = itemEntity;
	
	NSArray *allItems = [self.managedObjectContext executeFetchRequest:allItemsRequest error:NULL];
	for (GLLItem *item in allItems)
		[self _addDrawerForItem:item];
	
	// Prepare light buffer. Set almost all to 0; it will get updated later.
	glGenBuffers(1, &lightBuffer);
	glBindBuffer(GL_UNIFORM_BUFFER, lightBuffer);
	struct GLLLightBlock lightBlock;
	bzero(&lightBlock, sizeof(lightBlock));
	lightBlock.cameraLocation = simd_make(0.0, 1.0, 2.0, 1.0);
	glBufferData(GL_UNIFORM_BUFFER, sizeof(lightBlock), &lightBlock, GL_DYNAMIC_DRAW);
	
	// Load existing lights
	NSFetchRequest *allLightsRequest = [[NSFetchRequest alloc] init];
	allLightsRequest.entity = [NSEntityDescription entityForName:@"GLLLight" inManagedObjectContext:self.managedObjectContext];
	allLightsRequest.sortDescriptors = @[ [NSSortDescriptor sortDescriptorWithKey:@"index" ascending:YES] ];
	lights = [self.managedObjectContext executeFetchRequest:allLightsRequest error:NULL];
	
	NSAssert(lights.count == 4, @"There are not four lights.");
	
	// Register for ambient light color updates
	[lights[0] addObserver:self forKeyPath:@"color" options:NSKeyValueObservingOptionNew | NSKeyValueObservingOptionInitial context:NULL];
	// Register for directional light color updates
	for (int i = 0; i < 3; i++)
		[lights[i + 1] addObserver:self forKeyPath:@"dataAsUniformBlock" options:NSKeyValueObservingOptionInitial | NSKeyValueObservingOptionNew context:NULL];
	
	// Transform buffer
	glGenBuffers(1, &transformBuffer);
	glBindBuffer(GL_UNIFORM_BUFFER, transformBuffer);
	
	mat_float16 identity = simd_mat_identity();
	glBufferData(GL_UNIFORM_BUFFER, sizeof(identity), &identity, GL_STATIC_DRAW);
	[view addObserver:self forKeyPath:@"camera.viewProjectionMatrixData" options:NSKeyValueObservingOptionInitial | NSKeyValueObservingOptionNew context:0];
	
	// Alpha test buffer
	glGenBuffers(1, &alphaTestDisabledBuffer);
	glBindBuffer(GL_UNIFORM_BUFFER, alphaTestDisabledBuffer);
	struct GLLAlphaTestBlock alphaBlock = { .mode = 0, .reference = .9 };
	glBufferData(GL_UNIFORM_BUFFER, sizeof(alphaBlock), &alphaBlock, GL_STATIC_DRAW);
	glGenBuffers(1, &alphaTestPassGreaterBuffer);
	glBindBuffer(GL_UNIFORM_BUFFER, alphaTestPassGreaterBuffer);
	alphaBlock.mode = 1;
	glBufferData(GL_UNIFORM_BUFFER, sizeof(alphaBlock), &alphaBlock, GL_STATIC_DRAW);
	glGenBuffers(1, &alphaTestPassLessBuffer);
	glBindBuffer(GL_UNIFORM_BUFFER, alphaTestPassLessBuffer);
	alphaBlock.mode = 2;
	glBufferData(GL_UNIFORM_BUFFER, sizeof(alphaBlock), &alphaBlock, GL_STATIC_DRAW);
	
	// Other necessary render state. Thanks to Core Profile, that got cut down a lot.
	glEnable(GL_DEPTH_TEST);
	glEnable(GL_MULTISAMPLE);
	glClearColor(0.2, 0.2, 0.2, 1);
	
	glBlendFunc(GL_SRC_ALPHA, GL_ONE_MINUS_SRC_ALPHA);
	
	glEnable(GL_CULL_FACE);
	glFrontFace(GL_CW);
	
	self.view.needsDisplay = YES;
	
	return self;
}

- (void)dealloc
{
	[[NSNotificationCenter defaultCenter] removeObserver:managedObjectContextObserver];
	
	for (GLLItemDrawer *drawer in itemDrawers)
		[self _unregisterDrawer:drawer];
	
	[lights[0] removeObserver:self forKeyPath:@"color"];
	
	for (int i = 0; i < 3; i++)
		[lights[i + 1] removeObserver:self forKeyPath:@"dataAsUniformBlock"];
	
	[self.view removeObserver:self forKeyPath:@"camera.viewProjectionMatrixData"];
}

- (void)observeValueForKeyPath:(NSString *)keyPath ofObject:(id)object change:(NSDictionary *)change context:(void *)context
{
	if ([keyPath isEqual:@"needsRedraw"])
	{
		self.view.needsDisplay = YES;
	}
	else if ([keyPath isEqual:@"camera.viewProjectionMatrixData"])
	{
		if ([change[NSKeyValueChangeNewKey] isKindOfClass:[NSNull class]])
			return;
		
		[self.view.openGLContext makeCurrentContext];
		
		glBindBuffer(GL_UNIFORM_BUFFER, transformBuffer);
		glBufferData(GL_UNIFORM_BUFFER, [change[NSKeyValueChangeNewKey] length], [change[NSKeyValueChangeNewKey] bytes], GL_STATIC_DRAW);
		
		// Apply position to lighting data
		glBindBuffer(GL_UNIFORM_BUFFER, lightBuffer);
		vec_float4 position = [[object camera] cameraWorldPosition];
		glBufferSubData(GL_UNIFORM_BUFFER, offsetof(struct GLLLightBlock, cameraLocation), sizeof(position), &position);
		
		self.view.needsDisplay = YES;
	}
	else if ([keyPath isEqual:@"dataAsUniformBlock"])
	{
		NSUInteger index = [[object valueForKey:@"index"] unsignedIntegerValue];
		if (index >= 3) return;
		
		[self.view.openGLContext makeCurrentContext];
		
		NSData *value = change[NSKeyValueChangeNewKey];
		glBindBuffer(GL_UNIFORM_BUFFER, lightBuffer);
		glBufferSubData(GL_UNIFORM_BUFFER, offsetof(struct GLLLightBlock, lights[index]), value.length, value.bytes);
		
		self.view.needsDisplay = YES;
	}
	else if ([keyPath isEqual:@"color"])
	{
		[self.view.openGLContext makeCurrentContext];
		
		NSColor *value = change[NSKeyValueChangeNewKey];
		CGFloat r, g, b, a;
		[[value colorUsingColorSpace:[NSColorSpace genericRGBColorSpace]] getRed:&r green:&g blue:&b alpha:&a];
		vec_float4 ambientColor = simd_make(r, g, b, a);
		glBindBuffer(GL_UNIFORM_BUFFER, lightBuffer);
		glBufferSubData(GL_UNIFORM_BUFFER, offsetof(struct GLLLightBlock, ambientColor), sizeof(ambientColor), &ambientColor);
		
		self.view.needsDisplay = YES;
	}
	else
	{
		[super observeValueForKeyPath:keyPath ofObject:object change:change context:context];
	}
}

- (void)draw;
{
	glClear(GL_COLOR_BUFFER_BIT | GL_DEPTH_BUFFER_BIT);
	
	glBindBufferBase(GL_UNIFORM_BUFFER, GLLUniformBlockBindingLights, lightBuffer);
	glBindBufferBase(GL_UNIFORM_BUFFER, GLLUniformBlockBindingTransforms, transformBuffer);
	
	// 1st pass: Draw items that do not need blending, without alpha test
	glBindBufferBase(GL_UNIFORM_BUFFER, GLLUniformBlockBindingAlphaTest, alphaTestDisabledBuffer);
	
	for (GLLItemDrawer *drawer in itemDrawers)
		[drawer drawSolid];
	
	// 2nd pass: Draw blended items, but only those pixels that are "almost opaque"
	glBindBufferBase(GL_UNIFORM_BUFFER, GLLUniformBlockBindingAlphaTest, alphaTestPassGreaterBuffer);
	
	glEnable(GL_BLEND);
	
	for (GLLItemDrawer *drawer in itemDrawers)
		[drawer drawAlpha];
	
	// 3rd pass: Draw blended items, now only those things that are "mostly transparent".
	glBindBufferBase(GL_UNIFORM_BUFFER, GLLUniformBlockBindingAlphaTest, alphaTestPassLessBuffer);
	
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
	NSError *error = nil;
	GLLItemDrawer *drawer = [[GLLItemDrawer alloc] initWithItem:item sceneDrawer:self error:&error];
	
	if (!drawer)
	{
		[self.view presentError:error];
		return;
	}
	
	[itemDrawers addObject:drawer];
	[drawer addObserver:self forKeyPath:@"needsRedraw" options:0 context:0];
}
- (void)_unregisterDrawer:(GLLItemDrawer *)drawer
{
	[drawer removeObserver:self forKeyPath:@"needsRedraw"];
	[drawer unload];
}

@end
