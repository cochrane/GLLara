//
//  GLLItemBone.m
//  GLLara
//
//  Created by Torsten Kammer on 01.09.12.
//  Copyright (c) 2012 Torsten Kammer. All rights reserved.
//

#import "GLLItemBone.h"

#import "GLLItem.h"
#import "GLLModel.h"
#import "GLLModelBone.h"
#import "simd_matrix.h"
#import "TRInDataStream.h"
#import "TROutDataStream.h"

@interface GLLItemBone ()
{
    NSArray *children;
    NSUInteger cachedBoneIndex;
}

- (void)_standardSetValue:(id)value forKey:(NSString *)key;
- (void)_standardSetAngle:(float)value forKey:(NSString *)key;
- (void)_updateRelativeTransform;

@end

@implementation GLLItemBone

+ (NSSet *)keyPathsForValuesAffectingBone
{
    return [NSSet setWithObjects:@"item.model.bones", @"boneIndex", nil];
}

@dynamic positionX;
@dynamic positionY;
@dynamic positionZ;
@dynamic rotationX;
@dynamic rotationY;
@dynamic rotationZ;
@dynamic boneIndex;

@synthesize parent;
@synthesize relativeTransform;
@synthesize globalTransform;
@synthesize globalTransformValue;
@synthesize globalPosition;

- (void)awakeFromFetch
{
    [super awakeFromFetch];
    [self _updateRelativeTransform];
}
- (void)awakeFromInsert
{
    [super awakeFromInsert];
    [self _updateRelativeTransform];
}
- (void)awakeFromSnapshotEvents:(NSSnapshotEventType)flags
{
    [super awakeFromSnapshotEvents:flags];
    [self _updateRelativeTransform];
}

- (void)setPositionX:(float)position
{
    [self _standardSetValue:@(position) forKey:@"positionX"];
}
- (void)setPositionY:(float)position
{
    [self _standardSetValue:@(position) forKey:@"positionY"];
}
- (void)setPositionZ:(float)position
{
    [self _standardSetValue:@(position) forKey:@"positionZ"];
}

- (void)setRotationX:(float)angle
{
    [self _standardSetAngle:angle forKey:@"rotationX"];
}
- (void)setRotationY:(float)angle
{
    [self _standardSetAngle:angle forKey:@"rotationY"];
}
- (void)setRotationZ:(float)angle
{
    [self _standardSetAngle:angle forKey:@"rotationZ"];
}

- (BOOL)hasNonDefaultTransform {
    // Require matching 0 exactly, because set/reset to zero are done explicitly
    // to 0 constants, not the result of any maths.
    return self.positionX != 0.0
    || self.positionY != 0.0
    || self.positionZ != 0.0
    || self.rotationX != 0.0
    || self.rotationY != 0.0
    || self.rotationZ != 0.0;
}

- (void)resetAllValues {
    self.rotationX = 0.0;
    self.rotationY = 0.0;
    self.rotationZ = 0.0;
    self.positionX = 0.0;
    self.positionY = 0.0;
    self.positionZ = 0.0;
}

- (void)resetAllValuesRecursively {
    [self resetAllValues];
    [self.children makeObjectsPerformSelector:_cmd];
}

#pragma mark - Tree structure

- (NSUInteger)boneIndex
{
    if (cachedBoneIndex == NSNotFound) {
        cachedBoneIndex = [self.item.bones indexOfObject:self];
    }
    return cachedBoneIndex;
}

- (GLLModelBone *)bone
{
    return self.item.model.bones[self.boneIndex];
}

- (GLLItemBone *)parent
{
    if (!self.bone.parent) return nil;
    
    if (parent == nil)
        parent = self.item.bones[self.bone.parentIndex];
    
    return parent;
}

- (NSArray<GLLItemBone *> *)children
{
    if (!children) {
        NSOrderedSet<GLLItemBone *> *combinedBones = self.item.combinedBones;
        NSIndexSet *childIndices = [combinedBones indexesOfObjectsPassingTest:^BOOL(GLLItemBone *bone, NSUInteger idx, BOOL *stop){
            return bone.parent == self;
        }];
        children = [combinedBones objectsAtIndexes:childIndices];
    }
    return children;
}

- (NSUInteger)parentIndexInCombined
{
    if (self.parent)
        return [self.item.rootItem.combinedBones indexOfObject:self.parent];
    else
        return NSNotFound;
}

- (BOOL)isChildOfBone:(GLLItemBone *)bone;
{
    if (bone == self) return YES;
    else if (self.parent) return [self.parent isChildOfBone:bone];
    else return NO;
}
- (BOOL)isChildOfAny:(id)boneSet;
{
    if ([boneSet containsObject:self]) return YES;
    if (!self.parent) return NO;
    return [self.parent isChildOfAny:boneSet];
}

#pragma mark - Private methods

- (void)_standardSetValue:(id)value forKey:(NSString *)key;
{
    [self willChangeValueForKey:key];
    [self setPrimitiveValue:value forKey:key];
    [self didChangeValueForKey:key];
    [self _updateRelativeTransform];
}

- (void)_standardSetAngle:(float)value forKey:(NSString *)key;
{
    value = fmodf(value, M_PI * 2.0);
    if (value < 0.0f)
        value = M_PI * 2.0 - value;
    
    // Ugly hotfix for Bug #63 - limit range to shortly under 2π
    // TODO: In the Managed Object Model, up the limit for the angles to something like 7.0 and let this code here handle the details of keeping it in the 0…2π range.
    if (value > 6.283)
        value = 6.283;
    
    [self _standardSetValue:@(value) forKey:key];
}

- (void)_updateRelativeTransform
{
    cachedBoneIndex = NSNotFound;
    
    mat_float16 transform = simd_mat_positional(simd_make(self.positionX, self.positionY, self.positionZ, 1.0f));
    transform = simd_mul(transform, simd_mat_rotate(self.rotationY, simd_e_y));
    transform = simd_mul(transform, simd_mat_rotate(self.rotationX, simd_e_x));
    transform = simd_mul(transform, simd_mat_rotate(self.rotationZ, simd_e_z));
    
    self.relativeTransform = transform;
    
    [self updateGlobalTransform];
}
- (void)updateGlobalTransform;
{
    mat_float16 parentGlobalTransform;
    
    if (!self.parent)
        parentGlobalTransform = self.item.modelTransform;
    else
        parentGlobalTransform = self.parent.globalTransform;
    
    mat_float16 ownLocalTransform = self.relativeTransform;
    
    mat_float16 transform = self.bone.inversePositionMatrix;
    transform = simd_mul(ownLocalTransform, transform);
    transform = simd_mul(self.bone.positionMatrix, transform);
    transform = simd_mul(parentGlobalTransform, transform);
    
    self.globalTransform = transform;
    self.globalTransformValue = [NSData dataWithBytes:&transform length:sizeof(transform)];
    
    self.globalPosition = simd_mul(transform, simd_make(self.bone.positionX, self.bone.positionY, self.bone.positionZ, 1.0f));
    
    [self.children makeObjectsPerformSelector:@selector(updateGlobalTransform)];
}

- (GLLItem *)item
{
    NSOrderedSet<GLLItem *> *items = [self valueForKey:@"items"];
    if (items.count == 0) return nil;
    return [items objectAtIndex:0];
}

@end
