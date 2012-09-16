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

- (void)_standardSetValue:(id)value forKey:(NSString *)key;
- (void)_updateRelativeTransform;
- (void)_updateGlobalTransform;

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
@dynamic item;
@dynamic relativeTransform;
@dynamic globalTransform;
@dynamic globalPosition;

@synthesize parent;
@synthesize children;

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
	[self _updateRelativeTransform];
}
- (void)setPositionY:(float)position
{
	[self _standardSetValue:@(position) forKey:@"positionY"];
	[self _updateRelativeTransform];
}
- (void)setPositionZ:(float)position
{
	[self _standardSetValue:@(position) forKey:@"positionZ"];
	[self _updateRelativeTransform];
}

- (void)setRotationX:(float)position
{
	[self _standardSetValue:@(position) forKey:@"rotationX"];
	[self _updateRelativeTransform];
}
- (void)setRotationY:(float)position
{
	[self _standardSetValue:@(position) forKey:@"rotationY"];
	[self _updateRelativeTransform];
}
- (void)setRotationZ:(float)position
{
	[self _standardSetValue:@(position) forKey:@"rotationZ"];
	[self _updateRelativeTransform];
}

#pragma mark - Tree structure

- (NSUInteger)boneIndex
{
	return [self.item.bones indexOfObject:self];
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

- (NSArray *)children
{
	if (children == nil)
	{
		NSIndexSet *childIndices = [self.item.bones indexesOfObjectsPassingTest:^BOOL(GLLItemBone *bone, NSUInteger idx, BOOL *stop){
			return bone.parent == self;
		}];
		children = [self.item.bones objectsAtIndexes:childIndices];
	}
	
	return children;
}

#pragma mark - Source list item

- (BOOL)isSourceListHeader
{
	return NO;
}
- (NSString *)sourceListDisplayName
{
	return self.bone.name;
}
- (BOOL)hasChildrenInSourceList
{
	return self.children.count > 0;
}
- (NSUInteger)numberOfChildrenInSourceList
{
	return self.children.count;
}
- (id)childInSourceListAtIndex:(NSUInteger)index;
{
	return self.children[index];
}

#pragma mark - Private methods

- (void)_standardSetValue:(id)value forKey:(NSString *)key;
{
	[self willChangeValueForKey:key];
	[self setPrimitiveValue:value forKey:key];
	[self didChangeValueForKey:key];
}

- (void)_updateRelativeTransform
{
	mat_float16 transform = simd_mat_positional(simd_make(self.positionX, self.positionY, self.positionZ, 1.0f));
	transform = simd_mat_mul(transform, simd_mat_rotate(self.rotationY, simd_e_y));
	transform = simd_mat_mul(transform, simd_mat_rotate(self.rotationX, simd_e_x));
	transform = simd_mat_mul(transform, simd_mat_rotate(self.rotationZ, simd_e_z));
	
	self.relativeTransform = [NSValue valueWithBytes:&transform objCType:@encode(float [16])];
	
	[self _updateGlobalTransform];
}
- (void)_updateGlobalTransform
{
	if (!self.parent)
	{
		self.globalTransform = self.relativeTransform;
		for (GLLItemBone *child in self.children)
			[child _updateGlobalTransform];
		
		return;
	}
	
	mat_float16 parentGlobalTransform;
	[self.parent.globalTransform getValue:&parentGlobalTransform];

	mat_float16 ownLocalTransform;
	[self.relativeTransform getValue:&ownLocalTransform];
	
	mat_float16 transform = self.bone.inversePositionMatrix;
	transform = simd_mat_mul(ownLocalTransform, transform);
	transform = simd_mat_mul(self.bone.positionMatrix, transform);
	transform = simd_mat_mul(parentGlobalTransform, transform);

	self.globalTransform = [NSValue valueWithBytes:&transform objCType:@encode(float [16])];
	
	vec_float4 position = simd_mat_vecmul(transform, simd_make(self.bone.positionX, self.bone.positionY, self.bone.positionZ, 1.0f));
	self.globalPosition = [NSValue valueWithBytes:&position objCType:@encode(float [4])];
	
	for (GLLItemBone *child in self.children)
		[child _updateGlobalTransform];
}

@end
