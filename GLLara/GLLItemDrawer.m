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
#import "GLLModelMesh.h"
#import "GLLMeshDrawData.h"
#import "GLLModelDrawData.h"
#import "GLLResourceManager.h"
#import "GLLSceneDrawer.h"
#import "GLLItemMeshState.h"
#import "GLLUniformBlockBindings.h"
#import "simd_matrix.h"

@interface GLLItemDrawer ()
{
    GLuint transformsBuffer;
    BOOL needToUpdateTransforms;
    
    NSArray *meshStates;
    
    NSArray *bones;
    
    // Base arrays for runs. Size is meshStates.count
    GLsizei *allCounts;
    GLsizeiptr *allIndices;
    GLint *allBaseVertices;
    
    // Arrays for each run. Each element is an index into the base arrays.
    GLsizei solidRunCounts;
    GLsizei alphaRunCounts;
    GLsizei *runLengths;
    GLsizei *runStarts;
    NSArray *runStartStates;
    
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
    
    GLLModelDrawData *modelData = [sceneDrawer.resourceManager drawDataForModel:item.model error:error];
    if (!modelData)
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
    meshStates = [modelData.meshDatas map:^(GLLMeshDrawData *meshData) {
        return [[GLLItemMeshState alloc] initWithItemDrawer:self meshData:meshData itemMesh:[item itemMeshForModelMesh:meshData.modelMesh] error:error];
    }];
    if (meshStates.count < modelData.meshDatas.count)
    {
        [self unload];
        return nil;
    }
    
    glGenBuffers(1, &transformsBuffer);
    needToUpdateTransforms = YES;
    _needsRedraw = YES;
    
    allCounts = calloc(sizeof(GLsizei), meshStates.count);
    allBaseVertices = calloc(sizeof(GLint), meshStates.count);
    allIndices = calloc(sizeof(GLsizeiptr), meshStates.count);
    runLengths = calloc(sizeof(GLsizei), meshStates.count);
    runStarts = calloc(sizeof(GLsizei), meshStates.count);
    
    [self _findRuns];
    
    return self;
}

- (void)dealloc
{
    NSAssert(transformsBuffer == 0, @"Have to call unload first!");
}

- (void)observeValueForKeyPath:(NSString *)keyPath ofObject:(id)object change:(NSDictionary *)change context:(void *)context
{
    if ([keyPath isEqual:@"globalTransform"] || [keyPath isEqual:@"normalChannelAssignmentR"] || [keyPath isEqual:@"normalChannelAssignmentG"] || [keyPath isEqual:@"normalChannelAssignmentB"])
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
        GLLItemMeshState *meshState = runStartStates[run];
        [meshState setupState:state];
        
        GLsizei runStart = runStarts[run];
        GLsizei runLength = runLengths[run];
        glMultiDrawElementsBaseVertex(GL_TRIANGLES, allCounts + runStart, meshState.drawData.elementType, (GLvoid *) (allIndices + runStart), runLength, allBaseVertices + runStart);
    }
    
    self.needsRedraw = NO;
}
- (void)drawAlphaWithState:(GLLDrawState *)state;
{
    if (needToUpdateTransforms) [self _updateTransforms];
    if (needsUpdateRuns) [self _findRuns];
    
    glBindBufferBase(GL_UNIFORM_BUFFER, GLLUniformBlockBindingBoneMatrices, transformsBuffer);
    
    for (GLsizei run = solidRunCounts; run < (solidRunCounts + alphaRunCounts); run++) {
        GLLItemMeshState *meshState = runStartStates[run];
        [meshState setupState:state];
        
        GLsizei runStart = runStarts[run];
        GLsizei runLength = runLengths[run];
        glMultiDrawElementsBaseVertex(GL_TRIANGLES, allCounts + runStart, meshState.drawData.elementType, (GLvoid *) (allIndices + runStart), runLength, allBaseVertices + runStart);
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
    
    [meshStates makeObjectsPerformSelector:@selector(unload)];
    meshStates = nil;
    
    glDeleteBuffers(1, &transformsBuffer);
    transformsBuffer = 0;
    
    free(allCounts);
    free(allBaseVertices);
    free(allIndices);
    free(runLengths);
    free(runStarts);
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
    meshStates = [meshStates sortedArrayUsingComparator:^(GLLItemMeshState *a, GLLItemMeshState *b) {
        return [a compareTo:b];
    }];
    
    runStartStates = nil;
    NSMutableArray *startStates = [NSMutableArray array];
    
    NSUInteger nextRun = 0;
    GLsizei meshesAdded = 0;
    alphaRunCounts = 0;
    solidRunCounts = 0;
    
    // Find runs in meshes
    for (NSUInteger i = 0; i < meshStates.count; i++) {
        GLLItemMeshState *state = meshStates[i];
        if (!state.itemMesh.isVisible || !state.program) {
            continue;
        }
        
        if (i == 0 || [state compareTo:meshStates[i-1]] != NSOrderedSame) {
            // Starts new run
            runStarts[nextRun] = meshesAdded;
            runLengths[nextRun] = 1;
            [startStates addObject:state];
            if (state.itemMesh.isUsingBlending)
                alphaRunCounts += 1;
            else
                solidRunCounts += 1;
            nextRun += 1;
        } else {
            // Continues last run
            runLengths[nextRun - 1] += 1;
        }
        allBaseVertices[meshesAdded] = state.drawData.baseVertex;
        allIndices[meshesAdded] = state.drawData.indicesStart;
        allCounts[meshesAdded] = state.drawData.elementsCount;
        
        meshesAdded += 1;
    }
    
    runStartStates = startStates;
    needsUpdateRuns = NO;
}

- (void)propertiesChanged {
    self.needsRedraw = YES;
    needsUpdateRuns = YES;
}

@end
