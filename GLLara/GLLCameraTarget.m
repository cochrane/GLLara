//
//  GLLCameraTarget.m
//  GLLara
//
//  Created by Torsten Kammer on 09.09.12.
//  Copyright (c) 2012 Torsten Kammer. All rights reserved.
//

#import "GLLCameraTarget.h"
#import "GLLBoneTransformation.h"

#import "GLLItem.h"
#import "simd_functions.h"

@implementation GLLCameraTarget

+ (NSSet *)keyPathsForValuesAffectingDisplayName
{
	return [NSSet setWithObjects:@"name", @"bones", nil];
}

+ (NSSet *)keyPathsForValuesAffectingPosition
{
	return [NSSet setWithObject:@"bones.globalPosition"];
}

@dynamic name;
@dynamic bones;
@dynamic cameras;

- (NSString *)displayName
{
	return [NSString stringWithFormat:NSLocalizedString(@"%@ — %@", @"camera target name format"), self.name, [[self.bones.anyObject item] displayName]];
}

- (vec_float4)position
{
	vec_float4 position;
	for (GLLBoneTransformation *transform in self.bones)
		position += transform.globalPosition;
	
	return position / simd_splatf(self.bones.count);
}

@end
