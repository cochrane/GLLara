//
//  GLLModelObj.m
//  GLLara
//
//  Created by Torsten Kammer on 12.09.12.
//  Copyright (c) 2012 Torsten Kammer. All rights reserved.
//

#import "GLLModelObj.h"

#import "GLLBone.h"
#import "GLLMeshObj.h"
#import "GLLObjFile.h"

@interface GLLModelObj ()
{
	GLLObjFile *file;
}

@end

@implementation GLLModelObj

- (id)initWithContentsOfURL:(NSURL *)url;
{
	if (!(self = [super init])) return nil;

	file = new GLLObjFile((__bridge CFURLRef) url);
	
	// 1. Set up bones. We only have the one.
	self.bones = @[ [[GLLBone alloc] initWithModel:self] ];
	
	// 2. Set up meshes. We use one mesh per material group.
	NSMutableArray *meshes = [[NSMutableArray alloc] initWithCapacity:file->getMaterialRanges().size()];
	for (auto &range : file->getMaterialRanges())
	{
		[meshes addObject:[[GLLMeshObj alloc] initWithObjFile:file range:range]];
	}
	
	return self;
}

@end
