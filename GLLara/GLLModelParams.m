//
//  GLLModelHardcodedParams.m
//  GLLara
//
//  Created by Torsten Kammer on 01.09.12.
//  Copyright (c) 2012 Torsten Kammer. All rights reserved.
//

#import "GLLModelParams.h"

#import "GLLMesh.h"
#import "GLLMeshSplitter.h"
#import "GLLModel.h"
#import "GLLShaderDescriptor.h"

/*
 * Parsing of mesh names for generic item
 * Parts:
 *	Name - First anything without an underscore. Then (possibly several times) an underscore and an item that does not contain any numbers. This is necessary to parse meshes where someone put an underscore in the mesh name. Might be altered to allow anything that does not consist only of numbers and dots in the future.
 *	Number - digits and dots. Possibly several; I'll let someone else handle that.
 */
static NSString *meshNameRegexpString = @"^([0-9P]{1,2})_\
([^_\\n]+(?:_[^0-9\\n]+)*)\
(?:\
	_([\\d\\.]+)\
	(?:\
		_([\\d\\.]+)\
		(?:_([\\d\\.]+)\
			(?:\
				_([^_\\n]+(?:_[^0-9\\n]+)*)\
				(?:\
					_([^_\\n]+(?:_[^0-9\\n]+)*)\
				)*\
			)?\
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
	NSSet *ownShaders;
	NSDictionary *ownRenderParameters;
	NSDictionary *ownDefaultParameters;
	NSDictionary *ownMeshSplitters;
	NSString *defaultMeshGroup;
	
	GLLModel *model;
}

- (void)_parseModelName:(NSString *)name meshGroup:(NSString *__autoreleasing *)meshGroup renderParameters:(NSDictionary * __autoreleasing*)parameters cameraTargetName:(NSString *__autoreleasing*)name cameraTargetBones:(NSArray *__autoreleasing*)cameraTargetBones;

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
	if ([[name lowercaseString] isEqual:@"generic_item"])
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

@dynamic cameraTargets, meshesToSplit;

- (id)initWithPlist:(NSDictionary *)propertyList
{
	if (!(self = [super init])) return nil;
	
	// If there is a parent, get it
	if (propertyList[@"base"])
		_base = [[self class] parametersForName:propertyList[@"base"]];
	
	// Load the things that are easily to load.
	ownMeshGroups = propertyList[@"meshGroupNames"];
	ownShaders = propertyList[@"shaders"];
	ownRenderParameters = propertyList[@"renderParameters"];
	ownDefaultParameters = propertyList[@"defaultRenderParameters"];
	ownCameraTargets = propertyList[@"cameraTargets"];
	defaultMeshGroup = propertyList[@"defaultMeshGroup"];
	
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
	
	// Similar for loading shaders
	NSMutableSet *shaders = [[NSMutableSet alloc] initWithCapacity:[propertyList[@"shaders"] count]];
	for (NSString *shaderName in propertyList[@"shaders"])
		[shaders addObject:[[GLLShaderDescriptor alloc] initWithPlist:propertyList[@"shaders"][shaderName] name:shaderName baseURL:nil]];
	ownShaders = [shaders copy];
	
	return self;
}

// Generic item format
- (id)initWithModel:(GLLModel *)aModel;
{
	if (!(self = [super init])) return nil;
	
	_base = [[self class] parametersForName:@"lara"];
	model = aModel;
	
	// Objects that the generic_item format does not support.
	ownShaders = [NSSet set];
	ownDefaultParameters = @{};
	ownMeshSplitters = @{};
	
	// All others are nil
	ownCameraTargets = nil;
	ownMeshGroups = nil;
	ownRenderParameters = nil;
		
	return self;
}

#pragma mark - Mesh Groups

- (NSArray *)meshGroupsForMesh:(NSString *)meshName;
{
	if (!ownMeshGroups && model)
	{
		NSString *groupName = nil;
		[self _parseModelName:meshName meshGroup:&groupName renderParameters:NULL cameraTargetName:NULL cameraTargetBones:NULL];
		if (!groupName) return nil;
		return @[ groupName ];
	}
	
	NSMutableArray *result = [[NSMutableArray alloc] init];
	
	for (NSString *meshGroupName in ownMeshGroups)
	{
		if ([ownMeshGroups[meshGroupName] containsObject:meshName])
			[result addObject:meshGroupName];
	}
	
	if (self.base)
		[result addObjectsFromArray:[self.base meshGroupsForMesh:meshName]];
	
	if (result.count == 0 && defaultMeshGroup)
		[result addObject:defaultMeshGroup];
	
	return [result copy];
}

#pragma mark - Camera targets

- (NSArray *)cameraTargets
{
	if (!ownCameraTargets && model)
	{
		NSMutableSet *resultSet = [[NSMutableSet alloc] init];
		for (GLLMesh *mesh in model.meshes)
		{
			NSString *cameraTargetName = nil;
			[self _parseModelName:mesh.name meshGroup:NULL renderParameters:NULL cameraTargetName:&cameraTargetName cameraTargetBones:NULL];
			[resultSet addObject:mesh.name];
		}
		
		return [resultSet allObjects];
	}
	
	if (self.base)
		return [self.base.cameraTargets arrayByAddingObjectsFromArray:ownCameraTargets.allKeys];
	else
		return ownCameraTargets.allKeys;
}
- (NSArray *)boneNamesForCameraTarget:(NSString *)cameraTarget;
{
	if (!ownCameraTargets && model)
	{
		NSMutableArray *result = [[NSMutableArray alloc] init];
		for (GLLMesh *mesh in model.meshes)
		{
			NSString *cameraTargetName = nil;
			NSArray *cameraTargetBones;
			[self _parseModelName:mesh.name meshGroup:NULL renderParameters:NULL cameraTargetName:&cameraTargetName cameraTargetBones:&cameraTargetBones];
			if ([cameraTargetName isEqual:cameraTarget])
				[result addObjectsFromArray:cameraTargetBones];
		}
		
		return [result copy];
	}
	
	NSArray *result = ownCameraTargets[cameraTarget];
	if (!result) result = [NSArray array];
	
	if (self.base)
		result = [result arrayByAddingObjectsFromArray:[self.base boneNamesForCameraTarget:cameraTarget]];
	
	return result;
}

#pragma mark - Rendering

- (NSString *)renderableMeshGroupForMesh:(NSString *)mesh;
{
	for (NSString *meshGroup in [self meshGroupsForMesh:mesh])
	{
		GLLShaderDescriptor *shader = nil;
		BOOL isAlpha;
		[self getShader:&shader alpha:&isAlpha forMeshGroup:meshGroup];
		
		if (shader != nil)
			return meshGroup;
	}
	
	return nil;
}

- (void)getShader:(GLLShaderDescriptor *__autoreleasing *)shader alpha:(BOOL *)shaderIsAlpha forMeshGroup:(NSString *)meshGroup;
{
	// Try to find shader in own ones.
	for (GLLShaderDescriptor *descriptor in ownShaders)
	{
		if ([descriptor.solidMeshGroups containsObject:meshGroup])
		{
			if (shaderIsAlpha) *shaderIsAlpha = NO;
			if (shader) *shader = descriptor;
			return;
		}
		else if ([descriptor.alphaMeshGroups containsObject:meshGroup])
		{
			if (shaderIsAlpha) *shaderIsAlpha = YES;
			if (shader) *shader = descriptor;
			return;
		}
	}
	
	// No luck. Get those from the base.
	if (self.base)
		[self.base getShader:shader alpha:shaderIsAlpha forMeshGroup:meshGroup];
}

- (void)getShader:(GLLShaderDescriptor *__autoreleasing *)shader alpha:(BOOL *)shaderIsAlpha forMesh:(NSString *)mesh;
{
	[self getShader:shader alpha:shaderIsAlpha forMeshGroup:[self renderableMeshGroupForMesh:mesh]];
}
- (NSDictionary *)renderParametersForMesh:(NSString *)mesh;
{
	if (!ownRenderParameters && model)
	{
		NSMutableDictionary *result = [NSMutableDictionary dictionaryWithDictionary:[self.base renderParametersForMesh:mesh]];
		NSDictionary *forThisMesh = nil;
		[self _parseModelName:mesh meshGroup:NULL renderParameters:&forThisMesh cameraTargetName:NULL cameraTargetBones:NULL];
		[result addEntriesFromDictionary:forThisMesh];
		return result;
	}
	
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

#pragma mark - Splitting

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

#pragma mark - Private methods

- (void)_parseModelName:(NSString *)meshName meshGroup:(NSString *__autoreleasing *)meshGroup renderParameters:(NSDictionary * __autoreleasing*)renderParameters cameraTargetName:(NSString *__autoreleasing*)cameraTargetName cameraTargetBones:(NSArray *__autoreleasing*)cameraTargetBones;
{
	// Always use english locale, no matter what the user has set, for proper decimal separators.
	NSNumberFormatter *englishNumberFormatter = [[NSNumberFormatter alloc] init];
	englishNumberFormatter.locale = [[NSLocale alloc] initWithLocaleIdentifier:@"en_US"];
	englishNumberFormatter.formatterBehavior = NSNumberFormatterDecimalStyle;
	
	NSTextCheckingResult *components = [meshNameRegexp firstMatchInString:meshName options:NSMatchingAnchored range:NSMakeRange(0, meshName.length)];
	
	if (!components)
	{
		// See if we can satisfy that request from above
		if (meshGroup)
		{
			*meshGroup = [self.base renderableMeshGroupForMesh:meshName];
		}
		if (renderParameters)
		{
			*renderParameters = [self.base renderParametersForMesh:meshName];
		}
		if (cameraTargetName)
		{
			*cameraTargetName = nil;
		}
		if (cameraTargetBones)
		{
			*cameraTargetBones = nil;
		}
		return;
	}
	
	// 1st match: mesh group
	// Need this later for render parameters, so this part is always extracted.
	NSString *group = [@"MeshGroup" stringByAppendingString:[meshName substringWithRange:[components rangeAtIndex:1]]];
	if (meshGroup)
		*meshGroup = group;
	
	// 2nd match: mesh name - ignored.
	
	// 3rd, 4th, 5th match: render parameters
	if (renderParameters)
	{
		GLLShaderDescriptor *shader;
		[self getShader:&shader alpha:NULL forMeshGroup:group];
		
		NSArray *renderParameterNames = shader.parameterUniformNames;
		
		if (components.numberOfRanges < renderParameterNames.count + 3)
			NSLog(@"Mesh %@ does not have enough render parameters for shader %@ (has %lu, needs %lu). Rest will be set to 0.", meshName, shader.name, renderParameterNames.count, components.numberOfRanges - 3);
		
		NSMutableDictionary *renderParameterValues = [[NSMutableDictionary alloc] initWithCapacity:renderParameterNames.count];
		for (NSUInteger i = 0; i < renderParameterNames.count; i++)
		{
			if (i + 3 >= components.numberOfRanges)
				renderParameterValues[renderParameterNames[i]] = @0.0;
			else
				renderParameterValues[renderParameterNames[i]] = [englishNumberFormatter numberFromString:[meshName substringWithRange:[components rangeAtIndex:3 + i]]];
		}
		
		*renderParameters = [renderParameterValues copy];
	}
	
	// 6th match: Camera name
	if (cameraTargetName)
	{
		if (components.numberOfRanges <= 6)
			*cameraTargetName = nil;
		else
			*cameraTargetName = [meshName substringWithRange:[components rangeAtIndex:6]];
	}
	
	// Final matches: Camera bones
	if (cameraTargetBones)
	{
		if (components.numberOfRanges <= 7)
		{
			*cameraTargetBones = nil;
		}
		else
		{
			NSMutableArray *bones = [[NSMutableArray alloc] initWithCapacity:components.numberOfRanges - 7];
			for (NSUInteger i = 7; i < components.numberOfRanges; i++)
				[bones addObject:[meshName substringWithRange:[components rangeAtIndex:i]]];
			*cameraTargetBones = [bones copy];
		}
	}
}

@end
