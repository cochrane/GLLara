//
//  GLLBoneTransformation.m
//  GLLara
//
//  Created by Torsten Kammer on 01.09.12.
//  Copyright (c) 2012 Torsten Kammer. All rights reserved.
//

#import "GLLBoneTransformation.h"

#import "GLLBone.h"
#import "GLLItem.h"
#import "GLLModel.h"
#import "simd_matrix.h"
#import "TRInDataStream.h"
#import "TROutDataStream.h"

@implementation GLLBoneTransformation

+ (NSSet *)keyPathsForValuesAffectingBone
{
	return [NSSet setWithObjects:@"item.model.bones", @"boneIndex", nil];
}
+ (NSSet *)keyPathsForValuesAffectingHasParent
{
	return [NSSet setWithObjects:@"bone", nil];
}
+ (NSSet *)keyPathsForValuesAffectingRelativeTransform
{
	return [NSSet setWithObjects:@"positionX", @"positionY", @"positionZ", @"rotationX", @"rotationY", @"rotationZ", nil];
}
+ (NSSet *)keyPathsForValuesAffectingGlobalTransform
{
	return [NSSet setWithObjects:@"relativeTransform", @"parent.globalTransform", nil];
}

@dynamic positionX;
@dynamic positionY;
@dynamic positionZ;
@dynamic rotationX;
@dynamic rotationY;
@dynamic rotationZ;
@dynamic boneIndex;
@dynamic item;

@synthesize parent;
@synthesize children;

- (NSUInteger)boneIndex
{
	return [self.item.boneTransformations indexOfObject:self];
}

- (GLLBone *)bone
{
	return self.item.model.bones[self.boneIndex];
}

- (BOOL)hasParent
{
	return self.bone.hasParent;
}

- (GLLBoneTransformation *)parent
{
	if (!self.hasParent) return nil;
	
	if (parent == nil)
		parent = self.item.boneTransformations[self.bone.parentIndex];
	
	return parent;
}

- (NSArray *)children
{
	if (children == nil)
	{
		NSIndexSet *childIndices = [self.item.boneTransformations indexesOfObjectsPassingTest:^BOOL(GLLBoneTransformation *bone, NSUInteger idx, BOOL *stop){
			return bone.parent == self;
		}];
		children = [self.item.boneTransformations objectsAtIndexes:childIndices];
	}
	
	return children;
}

- (mat_float16)relativeTransform
{
	/*
	 * Movement plan:
	 * 1. Move bone from default to origin
	 * 2. Rotate bone
	 * 3. Move bone back to default + own position
	 */
	mat_float16 transform = simd_mat_positional(simd_make(-self.bone.positionX, -self.bone.positionY, -self.bone.positionZ, 1.0f));
	transform = simd_mat_mul(simd_mat_euler(simd_make(self.rotationX, self.rotationY, self.rotationZ, 1.0f), simd_e_w), transform);
	transform = simd_mat_mul(simd_mat_positional(simd_make(self.bone.positionX - self.positionX, self.bone.positionY - self.positionY, self.bone.positionZ - self.positionZ, 1.0f)), transform);
	
	return transform;
}

- (mat_float16)globalTransform
{
	if (!self.hasParent) return self.relativeTransform;
	
	return simd_mat_mul(self.parent.globalTransform, self.relativeTransform);
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

@end
