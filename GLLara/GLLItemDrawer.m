//
//  GLLItemDrawer.m
//  GLLara
//
//  Created by Torsten Kammer on 03.09.12.
//  Copyright (c) 2012 Torsten Kammer. All rights reserved.
//

#import "GLLItemDrawer.h"

#import <OpenGL/gl3.h>

#import "GLLItem.h"
#import "GLLItemBone.h"
#import "GLLMeshDrawer.h"
#import "GLLModelDrawer.h"
#import "GLLResourceManager.h"
#import "GLLSceneDrawer.h"
#import "GLLItemMeshDrawer.h"
#import "GLLUniformBlockBindings.h"
#import "simd_types.h"

@interface GLLItemDrawer ()
{
	GLuint transformsBuffer;
	BOOL needToUpdateTransforms;
	
	NSArray *alphaDrawers;
	NSArray *solidDrawers;
	
	NSArray *bones;
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
	// Store bones so we can unregister.
	// Getting the bones from the item to unregister may not work, because they may already be gone when the drawer gets unloaded.
	NSMutableArray *mutableBones = [[NSMutableArray alloc] initWithCapacity:item.bones.count];
	for (id transform in item.bones)
	{
		[mutableBones addObject:transform];
		[transform addObserver:self forKeyPath:@"globalTransform" options:0 context:0];
	}
	bones = [mutableBones copy];
	
	// Observe settings of all meshes
	NSMutableArray *mutableAlphaDrawers = [[NSMutableArray alloc] initWithCapacity:modelDrawer.alphaMeshDrawers.count];
	for (GLLMeshDrawer *drawer in modelDrawer.alphaMeshDrawers)
	{
		[mutableAlphaDrawers addObject:[[GLLItemMeshDrawer alloc] initWithItemDrawer:self meshDrawer:drawer itemMesh:[item itemMeshForModelMesh:drawer.modelMesh]]];
	}
	alphaDrawers = [mutableAlphaDrawers copy];
	
	NSMutableArray *mutableSolidDrawers = [[NSMutableArray alloc] initWithCapacity:modelDrawer.solidMeshDrawers.count];
	for (GLLMeshDrawer *drawer in modelDrawer.solidMeshDrawers)
	{
		[mutableSolidDrawers addObject:[[GLLItemMeshDrawer alloc] initWithItemDrawer:self meshDrawer:drawer itemMesh:[item itemMeshForModelMesh:drawer.modelMesh]]];
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
		needToUpdateTransforms = YES;
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
	
	for (GLLItemMeshDrawer *drawer in solidDrawers)
		[drawer draw];
	
	self.needsRedraw = NO;
}
- (void)drawAlpha;
{
	if (needToUpdateTransforms) [self _updateTransforms];
	
	glBindBufferBase(GL_UNIFORM_BUFFER, GLLUniformBlockBindingBoneMatrices, transformsBuffer);
	
	for (GLLItemMeshDrawer *drawer in alphaDrawers)
		[drawer draw];
	
	self.needsRedraw = NO;
}

- (void)unload;
{
	for (id bone in bones)
		[bone removeObserver:self forKeyPath:@"globalTransform"];
	bones = nil;
	
	for (GLLItemMeshDrawer *drawer in solidDrawers)
		[drawer unload];
	solidDrawers = nil;
	
	for (GLLItemMeshDrawer *drawer in alphaDrawers)
		[drawer unload];
	alphaDrawers = nil;
	
	glDeleteBuffers(1, &transformsBuffer);
	transformsBuffer = 0;
}

- (void)_updateTransforms
{	
	NSUInteger count = self.item.bones.count;
	mat_float16 *matrices = malloc(count * sizeof(mat_float16));
	for (NSUInteger i = 0; i < count; i++)
		[[[self.item.bones objectAtIndex:i] globalTransform] getValue:&matrices[i]];
	
	glBindBufferBase(GL_UNIFORM_BUFFER, GLLUniformBlockBindingBoneMatrices, transformsBuffer);
	glBufferData(GL_UNIFORM_BUFFER, count * sizeof(mat_float16), matrices, GL_STREAM_DRAW);
	
	free(matrices);
	
	needToUpdateTransforms = NO;
}

@end
