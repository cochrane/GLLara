//
//  GLLModelHardcodedParams.m
//  GLLara
//
//  Created by Torsten Kammer on 01.09.12.
//  Copyright (c) 2012 Torsten Kammer. All rights reserved.
//

#import "GLLModelParams.h"

#import "GLLMeshSplitter.h"
#import "GLLModel.h"
#import "GLLShaderList.h"

// Parsing of mesh names for generic item
static NSString *meshNameRegexpString = @"^(\\d{1,2})_\
([^A-Z_\\n]+)\
(?:\
	_([\\d\\.]+)\
	(?:\
		_([\\d\\.]+)\
		_([\\d\\.]+)\
		(?:\
			_([^A-Z_\\n]+)\
			(?:\
				_([^A-Z_\\n]+)\
			)+\
		)?\
	)?\
)?$";

static NSRegularExpression *meshNameRegexp;

// Storage for parameters
static NSCache *parameterCache;

@interface GLLModelParams ()
{
	NSDictionary *ownMeshGroups;
	NSDictionary *ownCameraTargets;
	NSDictionary *ownShadersForGroups;
	NSDictionary *ownShadersForGroupsAlpha;
	NSDictionary *ownRenderParameters;
	NSDictionary *ownDefaultParameters;
	NSDictionary *ownMeshSplitters;
}

@end

@implementation GLLModelParams

+ (void)initialize
{
	NSError *error = nil;
	meshNameRegexp = [[NSRegularExpression alloc] initWithPattern:meshNameRegexpString options:NSRegularExpressionAllowCommentsAndWhitespace | NSRegularExpressionAnchorsMatchLines error:&error];
	NSAssert(meshNameRegexp, @"Couldn't create mesh name regexp because of error: %@", error);
	
	parameterCache = [[NSCache alloc] init];
}

+ (id)parametersForModel:(GLLModel *)model;
{
	NSString *name = [[model.baseURL.lastPathComponent stringByDeletingPathExtension] stringByDeletingPathExtension];
	if ([name isEqual:@"generic_item"])
		return [[self alloc] initWithModel:model];
	else
		return [self parametersForName:name];
}

+ (id)parametersForName:(NSString *)name;
{
	id result = [parameterCache objectForKey:name];
	if (!result)
	{
		NSURL *plistURL = [[NSBundle mainBundle] URLForResource:name withExtension:@"modelparams.plist"];
		NSError *error = nil;
		result = [[self alloc] initWithPlist:[NSPropertyListSerialization propertyListWithData:[NSData dataWithContentsOfURL:plistURL] options:NSPropertyListImmutable format:NULL error:&error]];
		if (!result)
			[NSException raise:NSInvalidArgumentException format:@"Error trying to get parameters for name %@: %@", name, error];
		
		[parameterCache setObject:result forKey:name];
	}
	return result;
}

@dynamic meshGroups, cameraTargets, meshesToSplit;

- (id)initWithPlist:(NSDictionary *)propertyList
{
	if (!(self = [super init])) return nil;
	
	// If there is a parent, get it
	if (propertyList[@"base"])
		_base = [[self class] parametersForName:propertyList[@"base"]];
	
	// Load the things that are easily to load.
	ownMeshGroups = propertyList[@"meshGroupNames"];
	ownShadersForGroups = propertyList[@"shadersForGroups"];
	ownShadersForGroupsAlpha = propertyList[@"shadersForGroups"];
	ownRenderParameters = propertyList[@"renderParameters"];
	ownDefaultParameters = propertyList[@"defaultParameters"];
	ownCameraTargets = propertyList[@"cameratargets"];
	
	// Loading splitters is more complicated, because they are stored in their own class which handles a few nuisances automatically (in particular the fact that a mesh splitter does not usually define the full box).
	NSMutableDictionary *mutableMeshSplitters = [[NSMutableDictionary alloc] initWithCapacity:[propertyList[@"meshSplitters"] count]];
	for (NSString *originalMeshName in propertyList[@"meshSplitters"])
	{
		NSArray *splitterSpecifications = propertyList[@"meshSplitters"][originalMeshName];
		NSMutableArray *splitters = [[NSMutableArray alloc] initWithCapacity:splitterSpecifications.count];
		for (NSDictionary *spec in splitterSpecifications)
			[splitters addObject:[[GLLMeshSplitter alloc] initWithPlist:spec]];
		
		mutableMeshSplitters[originalMeshName] = splitters;
	}
	ownMeshSplitters = [mutableMeshSplitters copy];
	
	return self;
}

// Generic item format
- (id)initWithModel:(GLLModel *)model;
{
	if (!(self = [super init])) return nil;
	
	_base = [[self class] parametersForName:@"xnaLaraDefault"];
	
	// Objects that the generic_item format does not support.
	ownShadersForGroups = @{};
	ownShadersForGroupsAlpha = @{};
	ownDefaultParameters = @{};
	ownMeshSplitters = @{};
	
	NSMutableDictionary *mutableMeshGroups = [[NSMutableDictionary alloc] init];
	NSMutableDictionary *mutableCameraTargets = [[NSMutableDictionary alloc] init];
	NSMutableDictionary *mutableRenderParameters = [[NSMutableDictionary alloc] init];
	
	NSNumberFormatter *englishNumberFormatter = [[NSNumberFormatter alloc] init];
	englishNumberFormatter.locale = [[NSLocale alloc] initWithLocaleIdentifier:@"en_US"];
	englishNumberFormatter.formatterBehavior = NSNumberFormatterDecimalStyle;
	
	for (NSString *meshName in [model valueForKeyPath:@"meshes.name"])
	{
		NSTextCheckingResult *components = [meshNameRegexp firstMatchInString:meshName options:NSMatchingAnchored range:NSMakeRange(0, meshName.length)];
		
		// 1st match: mesh group
		NSString *meshGroup = [@"MeshGroup" stringByAppendingString:[meshName substringWithRange:[components rangeAtIndex:1]]];
		
		if (!mutableMeshGroups[meshGroup])
			mutableMeshGroups[meshGroup] = [NSMutableArray array];
		[mutableMeshGroups[meshGroup] addObject:meshName];
		
		// 2nd match: mesh name - ignored.
		
		// 3rd, 4th, 5th match: render parameters
		NSString *shader;
		[self getShader:&shader alpha:NULL forMeshGroup:meshGroup];
		
		NSArray *renderParameters = [[GLLShaderList defaultShaderList] renderParameterNamesForName:shader];
		
		if (components.numberOfRanges < renderParameters.count + 3)
			[NSException raise:NSInvalidArgumentException format:@"Does not specify enough render parameters"];
		
		NSMutableDictionary *renderParameterValues = [[NSMutableDictionary alloc] initWithCapacity:renderParameters.count];
		for (NSUInteger i = 0; i < renderParameters.count; i++)
			renderParameterValues[renderParameters[i]] = [englishNumberFormatter numberFromString:[meshName substringWithRange:[components rangeAtIndex:3 + i]]];
		mutableRenderParameters[meshName] = renderParameterValues;
		
		// 6th match: Camera name
		if (components.numberOfRanges <= 6) continue;
		NSString *cameraName = [meshName substringWithRange:[components rangeAtIndex:6]];
		
		NSMutableArray *bones = [[NSMutableArray alloc] initWithCapacity:components.numberOfRanges - 7];
		for (NSUInteger i = 7; i < components.numberOfRanges; i++)
			[bones addObject:[meshName substringWithRange:[components rangeAtIndex:i]]];
		
		mutableCameraTargets[cameraName] = bones;
	}
	
	ownMeshGroups = [mutableMeshGroups copy];
	ownCameraTargets = [mutableCameraTargets copy];
	ownRenderParameters = [mutableRenderParameters copy];
	
	return self;
}

#pragma mark -
#pragma mark Mesh Groups

- (NSArray *)meshGroups
{
	if (self.base)
		return [self.base.meshGroups arrayByAddingObjectsFromArray:ownMeshGroups.allKeys];
	else
		return ownMeshGroups.allKeys;
}
- (NSArray *)meshGroupsForMesh:(NSString *)meshName;
{
	NSMutableArray *result = [[NSMutableArray alloc] init];
	
	for (NSString *meshGroupName in ownMeshGroups)
	{
		if ([ownMeshGroups[meshGroupName] containsObject:meshName])
			[result addObject:meshGroupName];
	}
	
	if (self.base)
		[result addObjectsFromArray:[self.base meshGroupsForMesh:meshName]];
	
	return [result copy];
}
- (NSArray *)meshesForMeshGroup:(NSString *)meshGroup;
{
	NSArray *result = ownMeshGroups[meshGroup];
	if (!result) result = [NSArray array];
	
	if (self.base)
		result = [result arrayByAddingObjectsFromArray:[self.base meshesForMeshGroup:meshGroup]];
	
	return result;
}

#pragma mark -
#pragma mark Camera targets

- (NSArray *)cameraTargets
{
	if (self.base)
		return [self.base.cameraTargets arrayByAddingObjectsFromArray:ownCameraTargets.allKeys];
	else
		return ownCameraTargets.allKeys;
}
- (NSArray *)boneNamesForCameraTarget:(NSString *)cameraTarget;
{
	NSArray *result = ownCameraTargets[cameraTarget];
	if (!result) result = [NSArray array];
	
	if (self.base)
		result = [result arrayByAddingObjectsFromArray:[self.base boneNamesForCameraTarget:cameraTarget]];
	
	return result;
}

#pragma mark -
#pragma mark Rendering

- (NSString *)renderableMeshGroupForMesh:(NSString *)mesh;
{
	for (NSString *meshGroup in [self meshGroupsForMesh:mesh])
	{
		NSString *shader = nil;
		BOOL isAlpha;
		[self getShader:&shader alpha:&isAlpha forMeshGroup:meshGroup];
		
		if (shader != nil)
			return meshGroup;
	}
	
	return nil;
}

- (void)getShader:(NSString *__autoreleasing *)shader alpha:(BOOL *)shaderIsAlpha forMeshGroup:(NSString *)meshGroup;
{
	// 1. Look in solid shaders
	for (NSString *shaderName in ownShadersForGroups)
	{
		if ([ownShadersForGroups[shaderName] containsObject:meshGroup])
		{
			if (shaderIsAlpha) *shaderIsAlpha = NO;
			if (shader) *shader = shaderName;
			return;
		}
	}
	
	// 2. Look in alpha shaders
	for (NSString *shaderName in ownShadersForGroupsAlpha)
	{
		if ([ownShadersForGroups[shaderName] containsObject:meshGroup])
		{
			if (shaderIsAlpha) *shaderIsAlpha = YES;
			if (shader) *shader = shaderName;
			return;
		}
	}
	
	// 3. Look in parent
	if (self.base)
		[self.base getShader:shader alpha:shaderIsAlpha forMeshGroup:meshGroup];
}

- (void)getShader:(NSString *__autoreleasing *)shader alpha:(BOOL *)shaderIsAlpha forMesh:(NSString *)mesh;
{
	[self getShader:shader alpha:shaderIsAlpha forMeshGroup:[self renderableMeshGroupForMesh:mesh]];
}
- (NSDictionary *)renderParametersForMesh:(NSString *)mesh;
{
	// The parameters follow a hierarchy:
	// 1. anything from parent
	// 2. own default values
	// 3. own specific values
	// If the same parameter is set twice, then the one the highest in the hierarchy wins. E.g. if a value is set by the parent, then here in a default value and finally here specifically, then the specific value here is the one used.
	
	NSMutableDictionary *result = [NSMutableDictionary dictionary];	
	if (self.base)
		[result addEntriesFromDictionary:[self.base renderParametersForMesh:mesh]];
	if (ownDefaultParameters)
		[result addEntriesFromDictionary:ownDefaultParameters];
	
	[result addEntriesFromDictionary:ownRenderParameters[mesh]];

	return [result copy];
}

#pragma mark -
#pragma mark Splitting

- (NSArray *)meshesToSplit
{
	if (self.base)
		return [self.base.meshesToSplit arrayByAddingObjectsFromArray:ownMeshSplitters.allKeys];
	else
		return ownMeshSplitters.allKeys;
}
- (NSArray *)meshSplittersForMesh:(NSString *)mesh;
{
	NSArray *result = ownMeshSplitters[mesh];
	if (!result) result = [NSArray array];
	
	if (self.base)
		result = [result arrayByAddingObjectsFromArray:[self.base meshSplittersForMesh:mesh]];
	
	return result;
}

@end
