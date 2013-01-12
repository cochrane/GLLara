//
//  GLLItemDrawer.m
//  GLLara
//
//  Created by Torsten Kammer on 03.09.12.
//  Copyright (c) 2012 Torsten Kammer. All rights reserved.
//

#import "GLLItemDrawer.h"

#import <OpenGL/gl3.h>

#import "NSArray+Map.h"
#import "GLLItem.h"
#import "GLLItemBone.h"
#import "GLLMeshDrawer.h"
#import "GLLModelDrawer.h"
#import "GLLResourceManager.h"
#import "GLLSceneDrawer.h"
#import "GLLItemMeshDrawer.h"
#import "GLLUniformBlockBindings.h"
#import "simd_matrix.h"

@interface GLLItemDrawer ()
{
	GLuint transformsBuffer;
	BOOL needToUpdateTransforms;
	
	NSArray *alphaDrawers;
	NSArray *solidDrawers;
	
	NSArray *bones;
}

- (void)_updateTransforms;

- (vec_float4)_permutationTableColumn:(int16_t)mapping;

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
	
	[_item addObserver:self forKeyPath:@"normalChannelAssignmentR" options:0 context:0];
	[_item addObserver:self forKeyPath:@"normalChannelAssignmentG" options:0 context:0];
	[_item addObserver:self forKeyPath:@"normalChannelAssignmentB" options:0 context:0];
	
	// Observe all the bones
	// Store bones so we can unregister.
	// Getting the bones from the item to unregister may not work, because they may already be gone when the drawer gets unloaded.
	bones = [item.bones map:^(id transform){
		[transform addObserver:self forKeyPath:@"globalTransform" options:0 context:0];
		return transform;
	}];
	
	// Observe settings of all meshes
	alphaDrawers = [modelDrawer.alphaMeshDrawers map:^(GLLMeshDrawer *drawer) {
		return [[GLLItemMeshDrawer alloc] initWithItemDrawer:self meshDrawer:drawer itemMesh:[item itemMeshForModelMesh:drawer.modelMesh]];
	}];
	solidDrawers = [modelDrawer.solidMeshDrawers map:^(GLLMeshDrawer *drawer) {
		return [[GLLItemMeshDrawer alloc] initWithItemDrawer:self meshDrawer:drawer itemMesh:[item itemMeshForModelMesh:drawer.modelMesh]];
	}];
	
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
	else if ([keyPath isEqual:@"globalTransform"] || [keyPath isEqual:@"normalChannelAssignmentR"] || [keyPath isEqual:@"normalChannelAssignmentG"] || [keyPath isEqual:@"normalChannelAssignmentB"])
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
	[_item removeObserver:self forKeyPath:@"normalChannelAssignmentR"];
	[_item removeObserver:self forKeyPath:@"normalChannelAssignmentG"];
	[_item removeObserver:self forKeyPath:@"normalChannelAssignmentB"];
	
	for (id bone in bones)
		[bone removeObserver:self forKeyPath:@"globalTransform"];
	bones = nil;
	
	[solidDrawers makeObjectsPerformSelector:@selector(unload)];
	solidDrawers = nil;
	
	[solidDrawers makeObjectsPerformSelector:@selector(alphaDrawers)];
	alphaDrawers = nil;
	
	glDeleteBuffers(1, &transformsBuffer);
	transformsBuffer = 0;
}

- (void)_updateTransforms
{	
	NSUInteger count = self.item.bones.count;
	mat_float16 *matrices = malloc((count + 1) * sizeof(mat_float16));
	matrices[0].x = [self _permutationTableColumn:self.item.normalChannelAssignmentR];
	matrices[0].y = [self _permutationTableColumn:self.item.normalChannelAssignmentG];
	matrices[0].z = [self _permutationTableColumn:self.item.normalChannelAssignmentB];
	matrices[0].w = simd_e_w;
	for (NSUInteger i = 0; i < count; i++)
		[[[self.item.bones objectAtIndex:i] globalTransform] getValue:&matrices[i + 1]];
	
	glBindBufferBase(GL_UNIFORM_BUFFER, GLLUniformBlockBindingBoneMatrices, transformsBuffer);
	glBufferData(GL_UNIFORM_BUFFER, count * sizeof(mat_float16), matrices, GL_STREAM_DRAW);
	
	free(matrices);
	
	needToUpdateTransforms = NO;
}

- (vec_float4)_permutationTableColumn:(int16_t)mapping;
{
	switch (mapping)
	{
		case GLLNormalPos: return simd_e_z; break;
		case GLLNormalNeg: return -simd_e_z; break;
		case GLLTangentUPos: return simd_e_y; break;
		case GLLTangentUNeg: return -simd_e_y; break;
		case GLLTangentVPos: return simd_e_x; break;
		case GLLTangentVNeg: return -simd_e_x; break;
		default: return simd_zero();
	}
}

@end
