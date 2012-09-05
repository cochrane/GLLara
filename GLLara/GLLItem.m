//
//  GLLItem.m
//  GLLara
//
//  Created by Torsten Kammer on 01.09.12.
//  Copyright (c) 2012 Torsten Kammer. All rights reserved.
//

#import "GLLItem.h"

#import "GLLBoneTransformation.h"
#import "GLLBone.h"
#import "GLLMesh.h"
#import "GLLMeshSettings.h"
#import "GLLModel.h"
#import "TRInDataStream.h"
#import "TROutDataStream.h"

#pragma mark Private classes

@interface GLLItem_MeshesSourceListMarker : NSObject <GLLSourceListItem>

- (id)initWithItem:(GLLItem *)item;
@property (nonatomic, weak, readonly) GLLItem *item;

@end

@implementation GLLItem_MeshesSourceListMarker

- (id)initWithItem:(GLLItem *)item
{
	if (!(self = [super init])) return nil;
	_item = item;
	return self;
}

- (BOOL)isSourceListHeader
{
	return NO;
}
- (NSString *)sourceListDisplayName
{
	return NSLocalizedString(@"Meshes", @"source list: meshes for items");
}
- (BOOL)hasChildrenInSourceList
{
	return YES;
}
- (NSUInteger)numberOfChildrenInSourceList
{
	return self.item.meshSettings.count;
}
- (id)childInSourceListAtIndex:(NSUInteger)index;
{
	return self.item.meshSettings[index];
}

@end

@interface GLLItem_BonesSourceListMarker : NSObject <GLLSourceListItem>

- (id)initWithItem:(GLLItem *)item;
@property (nonatomic, weak, readonly) GLLItem *item;

@end

@implementation GLLItem_BonesSourceListMarker

- (id)initWithItem:(GLLItem *)item
{
	if (!(self = [super init])) return nil;
	_item = item;
	return self;
}

- (BOOL)isSourceListHeader
{
	return NO;
}
- (NSString *)sourceListDisplayName
{
	return NSLocalizedString(@"Bones", @"source list: bones for items");
}
- (BOOL)hasChildrenInSourceList
{
	return YES;
}
- (NSUInteger)numberOfChildrenInSourceList
{
	return self.item.rootBoneTransformations.count;
}
- (id)childInSourceListAtIndex:(NSUInteger)index;
{
	return self.item.rootBoneTransformations[index];
}

@end

#pragma mark -

@interface GLLItem ()
{
	GLLItem_BonesSourceListMarker *bonesMarker;
	GLLItem_MeshesSourceListMarker *meshesMarker;
}

@end

@implementation GLLItem

- (id)initWithModel:(GLLModel *)model;
{
	if (!(self = [super init])) return nil;
	
	_model = model;
	bonesMarker = [[GLLItem_BonesSourceListMarker alloc] initWithItem:self];
	meshesMarker = [[GLLItem_MeshesSourceListMarker alloc] initWithItem:self];
	
	self.isVisible = YES;
	self.scaleX = 1.0f;
	self.scaleY = 1.0f;
	self.scaleZ = 1.0f;
	
	NSMutableArray *bones = [[NSMutableArray alloc] initWithCapacity:model.bones.count];
	for (GLLBone *bone in model.bones)
	{
		GLLBoneTransformation *transform = [[GLLBoneTransformation alloc] initWithItem:self bone:bone];
		[bones addObject:transform];
	}
	_boneTransformations = [bones copy];
	
	NSMutableArray *meshSettings = [[NSMutableArray alloc] initWithCapacity:model.meshes.count];
	for (GLLMesh *mesh in model.meshes)
	{
		GLLMeshSettings *settings = [[GLLMeshSettings alloc] initWithItem:self mesh:mesh];
		[meshSettings addObject:settings];
	}
	_meshSettings = [meshSettings copy];
	
	//for (GLLBoneTransformation *transform in _boneTransformations)
	//	[transform calculateLocalPositions];
	
	return self;
}
- (id)initFromDataStream:(TRInDataStream *)stream baseURL:(NSURL *)url version:(GLLSceneVersion)version;
{
	if (!(self = [super init])) return nil;
	
	_itemName = [stream readPascalString];
	if (version >= GLLSceneVersion_1_5)
		_itemDirectory = [stream readPascalString];
	else
		_itemDirectory = [_itemName lowercaseString];
	
	self.isVisible = [stream readUint8];
	
	if (version >= GLLSceneVersion_1_8)
	{
		self.scaleX = [stream readFloat32];
		self.scaleY = [stream readFloat32];
		self.scaleZ = [stream readFloat32];
	}
	else {
		float uniformScale = [stream readFloat32];
		self.scaleX = uniformScale;
		self.scaleY = uniformScale;
		self.scaleZ = uniformScale;
	}
	
	// Load model
	_model = nil;
	
	// Pose
	
	
	return self;
}

- (void)writeToStream:(TROutDataStream *)stream;
{
	
}

- (NSString *)displayName
{
	NSMutableString *basicName = [[NSMutableString alloc] initWithString:self.model.baseURL.lastPathComponent];
	
	if ([basicName hasSuffix:@".ascii"])
		[basicName deleteCharactersInRange:NSMakeRange(basicName.length - @".ascii".length, @".ascii".length)];
	if ([basicName hasSuffix:@".mesh"])
		[basicName deleteCharactersInRange:NSMakeRange(basicName.length - @".mesh".length, @".mesh".length)];
	
	[basicName replaceOccurrencesOfString:@"_" withString:@" " options:0 range:NSMakeRange(0, basicName.length)];
	
	CFStringTransform((__bridge CFMutableStringRef) basicName, NULL, CFSTR("Title"), NO);
	
	return [basicName copy];
}

- (NSArray *)rootBoneTransformations
{
	return [self.boneTransformations filteredArrayUsingPredicate:[NSPredicate predicateWithBlock:^BOOL(GLLBoneTransformation *bone, NSDictionary *bindings){
		return !bone.hasParent;
	}]];
}

- (void)getTransforms:(mat_float16 *)matrices maxCount:(NSUInteger)maxCount forMesh:(GLLMesh *)mesh;
{
	NSArray *boneIndices = mesh.boneIndices;
	NSUInteger max = MIN(maxCount, boneIndices.count);
	for (NSUInteger i = 0; i < max; i++)
		matrices[i] = [_boneTransformations[[boneIndices[i] unsignedIntegerValue]] globalTransform];
}

#pragma mark - Source List Item

- (BOOL)isSourceListHeader
{
	return NO;
}
- (NSString *)sourceListDisplayName
{
	return self.displayName;
}
- (BOOL)hasChildrenInSourceList
{
	return YES;
}
- (NSUInteger)numberOfChildrenInSourceList
{
	return 2;
}
- (id)childInSourceListAtIndex:(NSUInteger)index;
{
	if (index == 0) return meshesMarker;
	else if (index == 1) return bonesMarker;
	else return nil;
}

@end
