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
	self.globalPositionX = bone.defaultPositionX;
	self.globalPositionY = bone.defaultPositionY;
	self.globalPositionZ = bone.defaultPositionZ;
	
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

- (void)calculateLocalPositions;
{
	self.positionX = self.globalPositionX - self.parent.globalPositionX;
	self.positionX = self.globalPositionY - self.parent.globalPositionY;
	self.positionX = self.globalPositionZ - self.parent.globalPositionZ;
	
	for (GLLBoneTransformation *child in self.children)
		[child calculateLocalPositions];
}

- (BOOL)hasParent
{
	return self.bone.hasParent;
}

- (GLLBoneTransformation *)parent
{
	if (!self.hasParent) return nil;
	
	return self.item.boneTransformations[self.bone.parentIndex];
}

- (NSArray *)children
{
	return [self.item.boneTransformations filteredArrayUsingPredicate:[NSPredicate predicateWithBlock:^BOOL(GLLBoneTransformation *bone, NSDictionary *bindings){
		return bone.parent == self;
	}]];
}

- (mat_float16)relativeTransform
{
	return simd_mat_euler(simd_make(self.rotationX, self.rotationY, self.rotationZ, 1.0f), simd_make(self.positionX, self.positionY, self.positionZ, 1.0f));
}

- (mat_float16)globalTransform
{
	if (!self.parent) return self.relativeTransform;
	
	return simd_mat_mul(self.parent.globalTransform, self.relativeTransform);
}

@end
