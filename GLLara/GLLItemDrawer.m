//
//  GLLItemDrawer.m
//  GLLara
//
//  Created by Torsten Kammer on 03.09.12.
//  Copyright (c) 2012 Torsten Kammer. All rights reserved.
//

#import "GLLItemDrawer.h"

#import <OpenGL/gl3.h>

#import "GLLBoneTransformation.h"
#import "GLLItem.h"
#import "GLLMeshDrawer.h"
#import "GLLMeshSettings.h"
#import "GLLModelDrawer.h"
#import "GLLResourceManager.h"
#import "GLLSceneDrawer.h"
#import "GLLTransformedMeshDrawer.h"
#import "GLLUniformBlockBindings.h"
#import "simd_types.h"

@interface GLLItemDrawer ()
{
	GLuint transformsBuffer;
	BOOL needToUpdateTransforms;
	
	NSArray *alphaDrawers;
	NSArray *solidDrawers;
}

- (void)_updateTransforms;

@end

@implementation GLLItemDrawer

@synthesize needsRedraw=_needsRedraw;

- (id)initWithItem:(GLLItem *)item sceneDrawer:(GLLSceneDrawer *)sceneDrawer error:(NSError *__autoreleasing*)error;
{
	if (!(self = [super init])) return nil;
	
	_item = item;
	_sceneDrawer = sceneDrawer;
	
	GLLModelDrawer *modelDrawer = [sceneDrawer.resourceManager drawerForModel:item.model error:error];
	if (!modelDrawer)
		return nil;
	
	// Observe all the bones
	for (id transform in item.boneTransformations)
		[transform addObserver:self forKeyPath:@"globalTransform" options:0 context:0];
	
	NSMutableArray *mutableAlphaDrawers = [[NSMutableArray alloc] initWithCapacity:modelDrawer.alphaMeshDrawers.count];
	for (GLLMeshDrawer *drawer in modelDrawer.alphaMeshDrawers)
	{
		GLLTransformedMeshDrawer *transformedDrawer = [[GLLTransformedMeshDrawer alloc] initWithDrawer:drawer settings:[item settingsForMesh:drawer.mesh]];
		[transformedDrawer addObserver:self forKeyPath:@"drawer.mesh.renderSettings" options:0 context:0];
		[mutableAlphaDrawers addObject:transformedDrawer];
	}
	alphaDrawers = [mutableAlphaDrawers copy];
	
	NSMutableArray *mutableSolidDrawers = [[NSMutableArray alloc] initWithCapacity:modelDrawer.solidMeshDrawers.count];
	for (GLLMeshDrawer *drawer in modelDrawer.solidMeshDrawers)
	{
		GLLTransformedMeshDrawer *transformedDrawer = [[GLLTransformedMeshDrawer alloc] initWithDrawer:drawer settings:[item settingsForMesh:drawer.mesh]];
		[transformedDrawer addObserver:self forKeyPath:@"drawer.mesh.renderSettings" options:0 context:0];
		[mutableSolidDrawers addObject:transformedDrawer];
	}
	solidDrawers = [mutableSolidDrawers copy];
	
	glGenBuffers(1, &transformsBuffer);
	needToUpdateTransforms = YES;
	_needsRedraw = YES;
	
	return self;
}

- (void)dealloc
{
	NSAssert(transformsBuffer == 0, @"Have to call unload first!");
}

- (void)observeValueForKeyPath:(NSString *)keyPath ofObject:(id)object change:(NSDictionary *)change context:(void *)context
{
	if ([keyPath isEqual:@"drawer.mesh.renderSettings"])
	{
		self.needsRedraw = YES;
	}
	else if ([keyPath isEqual:@"globalTransform"])
	{
		self.needsRedraw = YES;
	}
	else [super observeValueForKeyPath:keyPath ofObject:object change:change context:context];
}

- (void)setNeedsRedraw:(BOOL)needsRedraw
{
	if (needsRedraw && !_needsRedraw)
	{
		[self willChangeValueForKey:@"needsRedraw"];
		_needsRedraw = needsRedraw;
		[self didChangeValueForKey:@"needsRedraw"];
	}
	else
		_needsRedraw = needsRedraw;
}

- (void)drawSolid;
{
	if (needToUpdateTransforms) [self _updateTransforms];
	
	glBindBufferBase(GL_UNIFORM_BUFFER, GLLUniformBlockBindingBoneMatrices, transformsBuffer);
	
	for (GLLTransformedMeshDrawer *drawer in solidDrawers)
		[drawer draw];
	
	self.needsRedraw = NO;
}
- (void)drawAlpha;
{
	if (needToUpdateTransforms) [self _updateTransforms];
	
	glBindBufferBase(GL_UNIFORM_BUFFER, GLLUniformBlockBindingBoneMatrices, transformsBuffer);
	
	for (GLLTransformedMeshDrawer *drawer in alphaDrawers)
		[drawer draw];
	
	self.needsRedraw = NO;
}

- (void)unload;
{
	for (id bone in self.item.boneTransformations)
		[bone removeObserver:self forKeyPath:@"globalTransform"];
	
	for (GLLTransformedMeshDrawer *drawer in solidDrawers)
	{
		[drawer removeObserver:self forKeyPath:@"drawer.mesh.renderSettings"];
		[drawer unload];
	}
	
	for (GLLTransformedMeshDrawer *drawer in alphaDrawers)
	{
		[drawer removeObserver:self forKeyPath:@"drawer.mesh.renderSettings"];
		[drawer unload];
	}
	
	glDeleteBuffers(1, &transformsBuffer);
	transformsBuffer = 0;
}

- (void)_updateTransforms
{
	glBindBuffer(GL_UNIFORM_BUFFER, transformsBuffer);
	
	NSUInteger count = self.item.boneTransformations.count;
	mat_float16 *matrices = malloc(count * sizeof(mat_float16));
	for (NSUInteger i = 0; i < count; i++)
		matrices[i] = [[self.item.boneTransformations objectAtIndex:i] globalTransform];
	
	glBufferData(GL_UNIFORM_BUFFER, count * sizeof(mat_float16), matrices, GL_STATIC_DRAW);
}

@end
