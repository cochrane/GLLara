//
//  GLLCameraTarget.m
//  GLLara
//
//  Created by Torsten Kammer on 09.09.12.
//  Copyright (c) 2012 Torsten Kammer. All rights reserved.
//

#import "GLLCameraTarget.h"
#import "GLLItemBone.h"

#import "GLLItem.h"
#import "simd_functions.h"

@implementation GLLCameraTarget

+ (NSSet *)keyPathsForValuesAffectingDisplayName
{
    return [NSSet setWithObjects:@"name", nil];
}

@dynamic position;

@dynamic name;
@dynamic bones;
@dynamic cameras;

- (NSString *)displayName
{
    return [NSString stringWithFormat:NSLocalizedString(@"%@ — %@", @"camera target name format"), self.name, [[self.bones.anyObject item] displayName]];
}

- (vec_float4)position
{
    vec_float4 newPosition = 0.0f;
    for (GLLItemBone *bone in self.bones) {
        newPosition += bone.globalPosition;
    }
    return newPosition / self.bones.count;
}

@end
