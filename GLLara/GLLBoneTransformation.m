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
#import "simd_matrix.h"
#import "TRInDataStream.h"
#import "TROutDataStream.h"

@implementation GLLBoneTransformation

@synthesize parent;
@synthesize children;

- (id)initFromDataStream:(TRInDataStream *)stream version:(GLLSceneVersion)version item:(GLLItem *)item bone:(GLLBone *)bone;
{
	if (!(self = [super init])) return nil;
	
	_item = item;
	_bone = bone;
	
	self.rotationX = [stream readFloat32];
	self.rotationY = [stream readFloat32];
	self.rotationZ = [stream readFloat32];
	
	if (version > GLLSceneVersion_1_3)
	{
		self.positionX = [stream readFloat32];
		self.positionY = [stream readFloat32];
		self.positionZ = [stream readFloat32];
	}
	
	return self;
}
- (id)initWithItem:(GLLItem *)item bone:(GLLBone *)bone;
{
	if (!(self = [super init])) return nil;
	
	_item = item;
	_bone = bone;
	
	self.rotationX = 0.0;
	self.rotationY = 0.0;
	self.rotationZ = 0.0;
	
	return self;
}

- (void)writeToStream:(TROutDataStream *)stream;
{
	[stream appendFloat32:self.rotationX];
	[stream appendFloat32:self.rotationY];
	[stream appendFloat32:self.rotationZ];
	
	[stream appendFloat32:self.positionX];
	[stream appendFloat32:self.positionY];
	[stream appendFloat32:self.positionZ];
}
- (BOOL)hasParent
{
	return self.bone.hasParent;
}

- (void)setRotationX:(float)rotationX
{
	_rotationX = rotationX;
	[self.item changedPosition];
}
- (void)setRotationY:(float)rotationY
{
	_rotationY = rotationY;
	[self.item changedPosition];
}
- (void)setRotationZ:(float)rotationZ
{
	_rotationZ = rotationZ;
	[self.item changedPosition];
}

- (void)setPositionX:(float)positionX
{
	_positionX = positionX;
	[self.item changedPosition];
}
- (void)setPositionY:(float)positionY
{
	_positionY = positionY;
	[self.item changedPosition];
}
- (void)setPositionZ:(float)positionZ
{
	_positionZ = positionZ;
	[self.item changedPosition];
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
		children = [self.item.boneTransformations filteredArrayUsingPredicate:[NSPredicate predicateWithBlock:^BOOL(GLLBoneTransformation *bone, NSDictionary *bindings){
			return bone.parent == self;
		}]];
	
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
