//
//  GLLPoseExporter.m
//  GLLara
//
//  Created by Torsten Kammer on 31.01.13.
//  Copyright (c) 2013 Torsten Kammer. All rights reserved.
//

#import "GLLPoseExporter.h"

#import "GLLItem.h"
#import "GLLItemBone.h"
#import "GLLModelBone.h"

@interface GLLPoseExporter ()

@property (nonatomic) id bonesList;

@end

@implementation GLLPoseExporter

- (id)initWithItem:(GLLItem *)item
{
	return [self initWithBones:item.bones];
}

- (id)initWithBones:(id)bones
{
	NSParameterAssert(bones);
	if (!(self = [super init])) return nil;
	
	self.bonesList = bones;
	
	return self;
}

- (NSString *)poseDescription
{
	NSMutableString *string = [[NSMutableString alloc] init];
	
	for (GLLItemBone *bone in self.bonesList)
	{
		if (self.skipUnused && [bone.bone.name hasPrefix:@"unused"])
			continue;
		
		[string appendFormat:@"%@: %f %f %f %f %f %f\r\n", bone.bone.name, bone.rotationX * 180.0 / M_PI, bone.rotationY * 180.0 / M_PI, bone.rotationZ * 180.0 / M_PI, bone.positionX, bone.positionY, bone.positionZ];
	}
	
	return [string copy];
}

@end
