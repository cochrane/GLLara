//
//  GLLModel.m
//  GLLara
//
//  Created by Torsten Kammer on 31.08.12.
//  Copyright (c) 2012 Torsten Kammer. All rights reserved.
//

#import "GLLModel.h"

#import "GLLASCIIScanner.h"
#import "GLLBone.h"
#import "GLLMesh.h"
#import "TRInDataStream.h"

static NSCache *cachedModels;

@implementation GLLModel

+ (void)initialize
{
	cachedModels = [[NSCache alloc] init];
}

+ (id)cachedModelFromFile:(NSURL *)file;
{
	id result = [cachedModels objectForKey:file.absoluteURL];
	if (!result)
	{
		if ([file.path hasSuffix:@".mesh"])
		{
			result = [[self alloc] initBinaryWithData:[NSData dataWithContentsOfURL:file]];
		}
		else if ([file.path hasSuffix:@".mesh.ascii"])
		{
			result = [[self alloc] initASCIIWithString:[NSString stringWithContentsOfURL:file usedEncoding:NULL error:NULL]];
		}
		else
			return nil;
		
		[cachedModels setObject:result forKey:file.absoluteURL];
	}
	return result;
}

- (id)initBinaryWithData:(NSData *)data;
{
	if (!(self = [super init])) return nil;
	
	TRInDataStream *stream = [[TRInDataStream alloc] initWithData:data];
	
	NSUInteger numBones = [stream readUint32];
	NSMutableArray *bones = [[NSMutableArray alloc] initWithCapacity:numBones];
	for (NSUInteger i = 0; i < numBones; i++)
		[bones addObject:[[GLLBone alloc] initFromStream:stream partOfModel:self]];
	_bones = [bones copy];
	
	NSUInteger numMeshes = [stream readUint32];
	NSMutableArray *meshes = [[NSMutableArray alloc] initWithCapacity:numMeshes];
	for (NSUInteger i = 0; i < numMeshes; i++)
		[meshes addObject:[[GLLMesh alloc] initFromStream:stream partOfModel:self]];
	_meshes = meshes;
	
	return self;
}

- (id)initASCIIWithString:(NSString *)string;
{
	if (!(self = [super init])) return nil;
	
	GLLASCIIScanner *scanner = [[GLLASCIIScanner alloc] initWithString:string];
	
	NSUInteger numBones = [scanner readUint32];
	NSMutableArray *bones = [[NSMutableArray alloc] initWithCapacity:numBones];
	for (NSUInteger i = 0; i < numBones; i++)
		[bones addObject:[[GLLBone alloc] initFromScanner:scanner partOfModel:self]];
	_bones = [bones copy];
	
	NSUInteger numMeshes = [scanner readUint32];
	NSMutableArray *meshes = [[NSMutableArray alloc] initWithCapacity:numMeshes];
	for (NSUInteger i = 0; i < numMeshes; i++)
		[meshes addObject:[[GLLMesh alloc] initFromScanner:scanner partOfModel:self]];
	_meshes = meshes;
	
	return self;
}

- (BOOL)hasBones
{
	return self.bones.count > 0;
}

- (NSArray *)rootBones
{
	return [self.bones filteredArrayUsingPredicate:[NSPredicate predicateWithBlock:^BOOL(GLLBone *bone, NSDictionary *bindings){
		return !bone.hasParent;
	}]];
}

@end
