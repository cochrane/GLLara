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
#import "GLLModelParams.h"
#import "TRInDataStream.h"

@interface GLLModel ()

// Adds a single mesh to the object, splitting it up into multiple parts if necessary (as specified by the model parameters). Also takes care to add it to the mesh groups and so on.
- (void)_addMesh:(GLLMesh *)mesh toArray:(NSMutableArray *)array;

@end

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
			result = [[self alloc] initBinaryFromFile:file];
		}
		else if ([file.path hasSuffix:@".mesh.ascii"])
		{
			result = [[self alloc] initASCIIFromFile:file];
		}
		else
			return nil;
		
		[cachedModels setObject:result forKey:file.absoluteURL];
	}
	return result;
}

- (id)initBinaryFromFile:(NSURL *)file;
{
	if (!(self = [super init])) return nil;
	
	_baseURL = file;
	_parameters = [GLLModelParams parametersForModel:self];
	
	TRInDataStream *stream = [[TRInDataStream alloc] initWithData:[NSData dataWithContentsOfURL:file]];
	
	NSUInteger numBones = [stream readUint32];
	NSMutableArray *bones = [[NSMutableArray alloc] initWithCapacity:numBones];
	for (NSUInteger i = 0; i < numBones; i++)
		[bones addObject:[[GLLBone alloc] initFromStream:stream partOfModel:self]];
	_bones = [bones copy];
	
	NSUInteger numMeshes = [stream readUint32];
	NSMutableArray *meshes = [[NSMutableArray alloc] initWithCapacity:numMeshes];
	for (NSUInteger i = 0; i < numMeshes; i++)
		[self _addMesh:[[GLLMesh alloc] initFromStream:stream partOfModel:self] toArray:meshes];
	_meshes = meshes;
	
	return self;
}

- (id)initASCIIFromFile:(NSURL *)file;
{
	if (!(self = [super init])) return nil;
	
	_baseURL = file;
	_parameters = [GLLModelParams parametersForModel:self];
	
	GLLASCIIScanner *scanner = [[GLLASCIIScanner alloc] initWithString:[NSString stringWithContentsOfURL:file usedEncoding:NULL error:NULL]];
	
	NSUInteger numBones = [scanner readUint32];
	NSMutableArray *bones = [[NSMutableArray alloc] initWithCapacity:numBones];
	for (NSUInteger i = 0; i < numBones; i++)
		[bones addObject:[[GLLBone alloc] initFromScanner:scanner partOfModel:self]];
	_bones = [bones copy];
	
	NSUInteger numMeshes = [scanner readUint32];
	NSMutableArray *meshes = [[NSMutableArray alloc] initWithCapacity:numMeshes];
	for (NSUInteger i = 0; i < numMeshes; i++)
		[self _addMesh:[[GLLMesh alloc] initFromScanner:scanner partOfModel:self] toArray:meshes];
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

#pragma mark -
#pragma mark Private methods

- (void)_addMesh:(GLLMesh *)mesh toArray:(NSMutableArray *)array;
{
	if ([self.parameters.meshesToSplit containsObject:mesh.name])
	{
		for (GLLMeshSplitter *splitter in [self.parameters meshSplittersForMesh:mesh.name])
			[array addObject:[mesh partialMeshFromSplitter:splitter]];
	}
	else
	{
		[array addObject:mesh];
	}
}

@end
