//
//  GLLModelObj.m
//  GLLara
//
//  Created by Torsten Kammer on 12.09.12.
//  Copyright (c) 2012 Torsten Kammer. All rights reserved.
//

#import "GLLModelObj.h"

#import "GLLModelBone.h"
#import "GLLModelMeshObj.h"
#import "GLLObjFile.h"

@interface GLLModelObj ()
{
	GLLObjFile *file;
}

@end

@implementation GLLModelObj

- (id)initWithContentsOfURL:(NSURL *)url error:(NSError *__autoreleasing*)error;
{
	if (!(self = [super init])) return nil;

	self.baseURL = url;
	
	try {
		file = new GLLObjFile((__bridge CFURLRef) url);
	} catch (std::exception &e) {
		if (error)
			*error = [NSError errorWithDomain:@"GLLModelObj" code:1 userInfo:@{ NSLocalizedDescriptionKey : NSLocalizedString(@"There was an error loading the file.", @"couldn't load obj file")}];
		NSLog(@"Exception: %s", e.what());
		return nil;
	}
	
	// 1. Set up bones. We only have the one.
	self.bones = @[ [[GLLModelBone alloc] initWithModel:self] ];
	
	// 2. Set up meshes. We use one mesh per material group.
	NSMutableArray *meshes = [[NSMutableArray alloc] initWithCapacity:file->getMaterialRanges().size()];
	NSUInteger meshNumber = 1;
	for (auto &range : file->getMaterialRanges())
	{
		GLLModelMeshObj *mesh = [[GLLModelMeshObj alloc] initWithObjFile:file range:range inModel:self error:error];
		if (!mesh) return nil;
		mesh.name = [NSString stringWithFormat:NSLocalizedString(@"Mesh %lu", "Mesh name for obj format"), meshNumber++];
		[meshes addObject:mesh];
	}
	self.meshes = [meshes copy];
	
	return self;
}

@end
