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
#import "LionSubscripting.h"

@interface GLLItemBone ()

- (void)_standardSetValue:(id)value forKey:(NSString *)key;
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
@synthesize children;
@synthesize relativeTransform;
@synthesize globalTransform;
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
}

- (void)_updateRelativeTransform
{
	mat_float16 transform = simd_mat_positional(simd_make(self.positionX, self.positionY, self.positionZ, 1.0f));
	transform = simd_mat_mul(transform, simd_mat_rotate(self.rotationY, simd_e_y));
	transform = simd_mat_mul(transform, simd_mat_rotate(self.rotationX, simd_e_x));
	transform = simd_mat_mul(transform, simd_mat_rotate(self.rotationZ, simd_e_z));
	
	self.relativeTransform = [NSValue valueWithBytes:&transform objCType:@encode(float [16])];
	
	[self updateGlobalTransform];
}
- (void)updateGlobalTransform;
{	
	mat_float16 parentGlobalTransform;
	
	if (!self.parent)
		parentGlobalTransform = self.item.modelTransform;
	else
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
	
	[self.children makeObjectsPerformSelector:@selector(updateGlobalTransform)];
}

- (GLLItem *)item
{
	NSOrderedSet *items = [self valueForKey:@"items"];
	if (items.count == 0) return nil;
	return [items objectAtIndex:0];
}

@end
