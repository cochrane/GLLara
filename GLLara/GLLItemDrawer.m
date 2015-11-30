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
#import "GLLItemMesh.h"
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
    
    // Base arrays for runs
    // Size is alpha drawers + solid drawers
    GLsizei *allCounts;
    GLsizeiptr *allIndices;
    GLint *allBaseVertices;
    
    // Arrays for each run. Each element is an index into the base arrays.
    GLsizei solidRunCounts;
    GLsizei alphaRunCounts;
    GLsizei *runLengths;
    GLsizei *runStarts;
    NSArray *runStartDrawers;
    
    BOOL needsUpdateRuns;
}

- (void)_updateTransforms;

- (vec_float4)_permutationTableColumn:(int16_t)mapping;

- (void)_findRuns;

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
		return [[GLLItemMeshDrawer alloc] initWithItemDrawer:self meshDrawer:drawer itemMesh:[item itemMeshForModelMesh:drawer.modelMesh] error:error];
	}];
	if (alphaDrawers.count < modelDrawer.alphaMeshDrawers.count)
	{
		[self unload];
		return nil;
	}
	solidDrawers = [modelDrawer.solidMeshDrawers map:^(GLLMeshDrawer *drawer) {
		return [[GLLItemMeshDrawer alloc] initWithItemDrawer:self meshDrawer:drawer itemMesh:[item itemMeshForModelMesh:drawer.modelMesh] error:error];
	}];
	if (solidDrawers.count < modelDrawer.solidMeshDrawers.count)
	{
		[self unload];
		return nil;
	}
    
	glGenBuffers(1, &transformsBuffer);
	needToUpdateTransforms = YES;
	_needsRedraw = YES;
    
    [self _findRuns];
	
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

- (void)drawSolidWithState:(GLLDrawState *)state;
{
	if (needToUpdateTransforms) [self _updateTransforms];
    if (needsUpdateRuns) [self _findRuns];
	
	glBindBufferBase(GL_UNIFORM_BUFFER, GLLUniformBlockBindingBoneMatrices, transformsBuffer);
    
    for (GLsizei run = 0; run < solidRunCounts; run++) {
        GLLItemMeshDrawer *drawer = runStartDrawers[run];
        [drawer setupState:state];
        
        GLsizei runStart = runStarts[run];
        GLsizei runLength = runLengths[run];
        glMultiDrawElementsBaseVertex(GL_TRIANGLES, allCounts + runStart, drawer.meshDrawer.elementType, (GLvoid *) (allIndices + runStart), runLength, allBaseVertices + runStart);
    }
	
	self.needsRedraw = NO;
}
- (void)drawAlphaWithState:(GLLDrawState *)state;
{
    if (needToUpdateTransforms) [self _updateTransforms];
    if (needsUpdateRuns) [self _findRuns];
	
    glBindBufferBase(GL_UNIFORM_BUFFER, GLLUniformBlockBindingBoneMatrices, transformsBuffer);
    
    for (GLsizei run = solidRunCounts; run < (solidRunCounts + alphaRunCounts); run++) {
        GLLItemMeshDrawer *drawer = runStartDrawers[run];
        [drawer setupState:state];
        
        GLsizei runStart = runStarts[run];
        GLsizei runLength = runLengths[run];
        glMultiDrawElementsBaseVertex(GL_TRIANGLES, allCounts + runStart, drawer.meshDrawer.elementType, (GLvoid *) (allIndices + runStart), runLength, allBaseVertices + runStart);
    }
	
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
	
	[alphaDrawers makeObjectsPerformSelector:@selector(unload)];
	alphaDrawers = nil;
	
	glDeleteBuffers(1, &transformsBuffer);
	transformsBuffer = 0;
}

- (void)_updateTransforms
{
	// The first matrix stores the normal transform, so make the buffer one
	// longer than needed for the bones themselves.
	NSUInteger boneCount = self.item.bones.count;
	NSUInteger matrixCount = boneCount + 1;
	
	glBindBufferBase(GL_UNIFORM_BUFFER, GLLUniformBlockBindingBoneMatrices, transformsBuffer);
	glBufferData(GL_UNIFORM_BUFFER, matrixCount * sizeof(mat_float16), NULL, GL_STREAM_DRAW);
    mat_float16 *matrices = glMapBuffer(GL_UNIFORM_BUFFER, GL_WRITE_ONLY);
    matrices[0].x = [self _permutationTableColumn:self.item.normalChannelAssignmentR];
    matrices[0].y = [self _permutationTableColumn:self.item.normalChannelAssignmentG];
    matrices[0].z = [self _permutationTableColumn:self.item.normalChannelAssignmentB];
    matrices[0].w = simd_e_w;
    for (NSUInteger i = 0; i < boneCount; i++)
        [[[self.item.bones objectAtIndex:i] globalTransform] getValue:&matrices[i + 1]];
    glUnmapBuffer(GL_UNIFORM_BUFFER);
	
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

- (void)_findRuns {
    solidDrawers = [solidDrawers sortedArrayUsingComparator:^NSComparisonResult(GLLItemMeshDrawer *a, GLLItemMeshDrawer *b) {
        return [a compareTo:b];
    }];
    alphaDrawers = [alphaDrawers sortedArrayUsingComparator:^NSComparisonResult(GLLItemMeshDrawer *a, GLLItemMeshDrawer *b) {
        return [a compareTo:b];
    }];

    
    NSUInteger totalMeshes = solidDrawers.count + alphaDrawers.count;
    if (!allCounts)
        allCounts = calloc(sizeof(GLsizei), totalMeshes);
    if (!allBaseVertices)
        allBaseVertices = calloc(sizeof(GLint), totalMeshes);
    if (!allIndices)
        allIndices = calloc(sizeof(GLsizeiptr), totalMeshes);
    if (!runLengths)
        runLengths = calloc(sizeof(GLsizei), totalMeshes);
    if (!runStarts)
        runStarts = calloc(sizeof(GLsizei), totalMeshes);
    runStartDrawers = nil;
    NSMutableArray *startDrawers = [NSMutableArray array];
    
    NSUInteger nextRun = 0;
    GLsizei meshesAdded = 0;
    alphaRunCounts = 0;
    solidRunCounts = 0;
    
    // Find runs in solid meshes
    GLLItemMeshDrawer *last = nil;
    for (GLLItemMeshDrawer *drawer in solidDrawers) {
        if (!drawer.itemMesh.isVisible) {
            continue;
        }
        
        if (last == nil || [drawer compareTo:last] != NSOrderedSame) {
            // Starts new run
            runStarts[nextRun] = meshesAdded;
            runLengths[nextRun] = 1;
            [startDrawers addObject:drawer];
            last = drawer;
            solidRunCounts += 1;
            nextRun += 1;
        } else {
            // Continues last run
            runLengths[nextRun - 1] += 1;
        }
        allBaseVertices[meshesAdded] = drawer.meshDrawer.baseVertex;
        allIndices[meshesAdded] = drawer.meshDrawer.indicesStart;
        allCounts[meshesAdded] = drawer.meshDrawer.elementsCount;
        
        meshesAdded += 1;
    }
    
    // Find runs in alpha meshes
    last = nil;
    for (GLLItemMeshDrawer *drawer in alphaDrawers) {
        if (!drawer.itemMesh.isVisible) {
            continue;
        }
        
        if (last == nil || [drawer compareTo:last] != NSOrderedSame) {
            // Starts new run
            runStarts[nextRun] = meshesAdded;
            runLengths[nextRun] = 1;
            [startDrawers addObject:drawer];
            last = drawer;
            alphaRunCounts += 1;
            nextRun += 1;
        } else {
            // Continues last run
            runLengths[nextRun - 1] += 1;
        }
        allBaseVertices[meshesAdded] = drawer.meshDrawer.baseVertex;
        allIndices[meshesAdded] = drawer.meshDrawer.indicesStart;
        allCounts[meshesAdded] = drawer.meshDrawer.elementsCount;
        
        meshesAdded += 1;
    }
    
    runStartDrawers = startDrawers;
    needsUpdateRuns = NO;
}

- (void)propertiesChanged {
    self.needsRedraw = YES;
    needsUpdateRuns = YES;
}

@end
