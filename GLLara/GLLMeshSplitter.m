//
//  GLLMeshSplitter.m
//  GLLara
//
//  Created by Torsten Kammer on 03.09.12.
//  Copyright (c) 2012 Torsten Kammer. All rights reserved.
//

#import "GLLMeshSplitter.h"

@interface GLLMeshSplitter ()
{
	float min[3];
	float max[3];
}

@end

@implementation GLLMeshSplitter

- (id)initWithPlist:(NSDictionary *)plist;
{
	if (!(self = [super init])) return nil;
	
	min[0] = min[1] = min[2] = -HUGE_VALF;
	max[0] = max[1] = max[2] = HUGE_VALF;
	
	_newName = plist[@"Name"];
	
	if (plist[@"minX"])
		min[0] = [plist[@"minX"] floatValue];
	
	if (plist[@"minY"])
		min[1] = [plist[@"minY"] floatValue];
	
	if (plist[@"minZ"])
		min[2] = [plist[@"minZ"] floatValue];
	
	if (plist[@"maxX"])
		max[0] = [plist[@"maxX"] floatValue];
	
	if (plist[@"maxY"])
		max[1] = [plist[@"maxY"] floatValue];
	
	if (plist[@"maxZ"])
		max[2] = [plist[@"maxZ"] floatValue];
	
	return self;
}

- (const float *)min
{
	return min;
}

- (const float *)max
{
	return min;
}

@end
