//
//  GLLModelHardcodedParams.m
//  GLLara
//
//  Created by Torsten Kammer on 01.09.12.
//  Copyright (c) 2012 Torsten Kammer. All rights reserved.
//

#import "GLLModelParams.h"

#import "NSArray+Map.h"
#import "GLLModelMesh.h"
#import "GLLMeshSplitter.h"
#import "GLLModel.h"
#import "GLLRenderParameterDescription.h"
#import "GLLShaderDescription.h"
#import "GLLTextureDescription.h"

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
_([^_\\n]+)\
(?:\
_([^_\\n]+)\
)*\
)?\
)?\
)?\
)?_?$";

static NSRegularExpression *meshNameRegexp;

// Storage for parameters
static NSCache *parameterCache;

@interface GLLModelParams ()
{
    NSDictionary<NSString *, NSArray<NSString *> *> *ownMeshGroups;
    NSDictionary<NSString *, NSArray<NSString *> *> *ownCameraTargets;
    NSDictionary<NSString *, GLLShaderDescription *> *ownShaders;
    NSDictionary<NSString *, id> *ownRenderParameters;
    NSDictionary<NSString *, id> *ownDefaultParameters;
    NSDictionary<NSString *, NSArray<GLLMeshSplitter *> *> *ownMeshSplitters;
    NSString *defaultMeshGroup;
    NSDictionary<NSString *, GLLRenderParameterDescription *> *ownRenderParameterDescriptions;
    NSDictionary<NSString *, GLLTextureDescription *> *ownTextureDescriptions;
    NSDictionary<NSString *, NSURL *> *ownDefaultTextures;
    
    // Cached, because in some situations this can take too much run time.
    NSArray<GLLShaderDescription *> *allShaders;
    
    GLLModel *model;
}

- (void)_parseMeshName:(NSString *)meshName displayName:(NSString *__autoreleasing*)displayName meshGroup:(NSString *__autoreleasing *)meshGroup renderParameters:(NSDictionary<NSString *, id> * __autoreleasing*)renderParameters cameraTargetName:(NSString *__autoreleasing*)cameraTargetName cameraTargetBones:(NSArray<NSString *> *__autoreleasing*)cameraTargetBones initiallyVisible:(BOOL * _Nullable )visible optionalPartNames:(NSArray<NSString *> *__autoreleasing _Nullable*)optionalPartNames;

@end

@implementation GLLModelParams

+ (void)initialize
{
    NSError *error = nil;
    meshNameRegexp = [[NSRegularExpression alloc] initWithPattern:meshNameRegexpString options:NSRegularExpressionAllowCommentsAndWhitespace | NSRegularExpressionAnchorsMatchLines error:&error];
    NSAssert(meshNameRegexp, @"Couldn't create mesh name regexp because of error: %@", error);
    
    parameterCache = [[NSCache alloc] init];
}

+ (id)parametersForModel:(GLLModel *)model error:(NSError *__autoreleasing *)error;
{
    // Check whether it is an XPS file
    NSArray<NSString *> *typeIdentifiersForFile = (__bridge_transfer NSArray<NSString *> *)UTTypeCreateAllIdentifiersForTag(kUTTagClassFilenameExtension, (__bridge CFStringRef)model.baseURL.pathExtension, NULL);
    if ([typeIdentifiersForFile containsObject:@"com.home-forum.xnalara.xpsmesh"])
        return [[self alloc] initWithModel:model error:error];
    
    NSString *name = [[model.baseURL.lastPathComponent stringByDeletingPathExtension] stringByDeletingPathExtension];
    if ([[name lowercaseString] isEqual:@"generic_item"])
        return [[self alloc] initWithModel:model error:error];
    else if ([[name lowercaseString] isEqual:@"character"])
        return [[self alloc] initWithModel:model error:error];
    else if ([[name lowercaseString] isEqual:@"outfit"])
        return [[self alloc] initWithModel:model error:error];
    else
        return [self parametersForName:name error:error];
}

+ (id)parametersForName:(NSString *)name error:(NSError *__autoreleasing *)error;
{
    id result = [parameterCache objectForKey:name];
    if (!result)
    {
        NSURL *plistURL = [[NSBundle mainBundle] URLForResource:name withExtension:@"modelparams.plist"];
        if (!plistURL)
        {
            if (error)
                *error = [NSError errorWithDomain:@"GLLModelParams" code:1 userInfo:@{
                                                                                      NSLocalizedDescriptionKey : [NSString stringWithFormat:NSLocalizedString(@"Did not find model parameters for model type %@", @"Bundle didn't find Modelparams file."), name],
                                                                                      NSLocalizedRecoverySuggestionErrorKey : NSLocalizedString(@"GLLara stores special information for files not named generic_item. This information is not available", @"Bundle didn't find Modelparams file.")
                                                                                      }];
            return nil;
        }
        
        NSData *data = [NSData dataWithContentsOfURL:plistURL options:0 error:error];
        if (!data) return nil;
        
        NSDictionary *plist = [NSPropertyListSerialization propertyListWithData:data options:NSPropertyListImmutable format:NULL error:error];
        if (!plist) return nil;
        
        result = [[self alloc] initWithPlist:plist error:error];
        if (!result) return nil;
        
        [parameterCache setObject:result forKey:name];
    }
    return result;
}

@dynamic cameraTargets, meshesToSplit;

- (id)initWithPlist:(NSDictionary *)propertyList error:(NSError *__autoreleasing *)error;
{
    if (!(self = [super init])) return nil;
    
    // If there is a parent, get it
    if (propertyList[@"base"])
    {
        _base = [[self class] parametersForName:propertyList[@"base"] error:error];
        if (!_base) return nil;
    }
    
    // Load the things that are easily to load.
    ownMeshGroups = propertyList[@"meshGroupNames"];
    ownShaders = propertyList[@"shaders"];
    ownRenderParameters = propertyList[@"renderParameters"];
    ownDefaultParameters = propertyList[@"defaultRenderParameters"];
    ownCameraTargets = propertyList[@"cameraTargets"];
    defaultMeshGroup = propertyList[@"defaultMeshGroup"];
    
    // Loading splitters is more complicated, because they are stored in their own class which handles a few nuisances automatically (in particular the fact that a mesh splitter does not usually define the full box).
    ownMeshSplitters = [propertyList[@"meshSplitters"] mapValues:^(NSArray *splitterSpecifications) {
        return [splitterSpecifications map:^(NSDictionary *spec){
            return [[GLLMeshSplitter alloc] initWithPlist:spec];
        }];
    }];
    
    // Similar for loading shaders
    ownShaders = [propertyList[@"shaders"] mapValuesWithKey:^(NSString *shaderName, id description){
        return [[GLLShaderDescription alloc] initWithPlist:description name:shaderName baseURL:nil modelParameters:self];
    }];
    
    // And render parameters
    ownRenderParameterDescriptions = [propertyList[@"renderParameterDescriptions"] mapValues:^(id description){
        return [[GLLRenderParameterDescription alloc] initWithPlist:description];
    }];
    ownTextureDescriptions = [propertyList[@"textureDescriptions"] mapValues:^(id description){
        return [[GLLTextureDescription alloc] initWithPlist:description];
    }];
    ownDefaultTextures = [propertyList[@"defaultTextures"] mapValues:^(NSString *name){
        return [[NSBundle mainBundle] URLForResource:name withExtension:nil];
    }];
    
    return self;
}

// Generic item format
- (id)initWithModel:(GLLModel *)aModel error:(NSError *__autoreleasing*)error;
{
    if (!(self = [super init])) return nil;
    
    _base = [[self class] parametersForName:@"lara" error:error];
    if (!_base) return nil;
    model = aModel;
    
    // Objects that the generic_item format does not support.
    ownShaders = @{};
    ownDefaultParameters = @{};
    ownDefaultTextures = @{};
    ownMeshSplitters = @{};
    ownRenderParameterDescriptions = @{};
    
    // All others are nil
    ownCameraTargets = nil;
    ownMeshGroups = nil;
    ownRenderParameters = nil;
    ownTextureDescriptions = nil;
    
    return self;
}

#pragma mark - Mesh Groups

- (NSArray<NSString *> *)meshGroupsForMesh:(NSString *)meshName;
{
    if (!ownMeshGroups && model)
    {
        NSString *groupName = nil;
        [self _parseMeshName:meshName displayName:NULL meshGroup:&groupName renderParameters:NULL cameraTargetName:NULL cameraTargetBones:NULL initiallyVisible:NULL optionalPartNames:NULL];
        if (!groupName) return nil;
        return @[ groupName ];
    }
    
    NSMutableArray<NSString *> *result = [[NSMutableArray alloc] init];
    
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

- (NSArray<NSString *> *)cameraTargets
{
    if (!ownCameraTargets && model)
    {
        NSArray<NSString *> *targets = [model.meshes map:^(GLLModelMesh *mesh){
            NSString *cameraTargetName = nil;
            [self _parseMeshName:mesh.name displayName:NULL meshGroup:NULL renderParameters:NULL cameraTargetName:&cameraTargetName cameraTargetBones:NULL initiallyVisible:NULL optionalPartNames:NULL];
            return cameraTargetName;
        }];
        
        // Remove duplicates by converting to NSSet and back
        NSSet<NSString *> *uniqueTargets = [NSSet setWithArray:targets];
        return uniqueTargets.allObjects;
    }
    
    NSMutableArray<NSString *> *cameraTargets = [NSMutableArray array];
    if (ownCameraTargets.count > 0)
        [cameraTargets addObjectsFromArray:ownCameraTargets.allKeys];
    if (self.base)
        [cameraTargets addObjectsFromArray:self.base.cameraTargets];
    
    return [cameraTargets copy];
}
- (NSArray<NSString *> *)boneNamesForCameraTarget:(NSString *)cameraTarget;
{
    if (!ownCameraTargets && model)
    {
        return [model.meshes mapAndJoin:^NSArray*(GLLModelMesh *mesh){
            NSString *cameraTargetName = nil;
            NSArray<NSString *> *cameraTargetBones;
            [self _parseMeshName:mesh.name displayName:NULL meshGroup:NULL renderParameters:NULL cameraTargetName:&cameraTargetName cameraTargetBones:&cameraTargetBones initiallyVisible:NULL optionalPartNames:NULL];
            if ([cameraTargetName isEqual:cameraTarget])
                return cameraTargetBones;
            else
                return nil;
        }];
    }
    
    NSArray<NSString *> *result = ownCameraTargets[cameraTarget];
    if (!result) result = [NSArray array];
    
    if (self.base)
        result = [result arrayByAddingObjectsFromArray:[self.base boneNamesForCameraTarget:cameraTarget]];
    
    return result;
}

#pragma mark - Mesh name

- (NSString *)displayNameForMesh:(NSString *)meshName;
{
    if (!ownCameraTargets && model)
    {
        NSString *displayName = nil;
        [self _parseMeshName:meshName displayName:&displayName meshGroup:NULL renderParameters:NULL cameraTargetName:NULL cameraTargetBones:NULL initiallyVisible:NULL optionalPartNames:NULL];
        if (displayName) return displayName;
    }
    
    return meshName;
}

#pragma mark - Rendering

- (NSString *)renderableMeshGroupForMesh:(NSString *)mesh;
{
    return [[self meshGroupsForMesh:mesh] firstObjectMatching:^(id meshGroup){
        GLLShaderDescription *shader = nil;
        BOOL isAlpha;
        [self getShader:&shader alpha:&isAlpha forMeshGroup:meshGroup];
        return (BOOL) (shader != nil);
    }];
}

- (void)getShader:(GLLShaderDescription *__autoreleasing *)shader alpha:(BOOL *)shaderIsAlpha forMeshGroup:(NSString *)meshGroup;
{
    // Try to find shader in own ones.
    for (NSString *shaderName in ownShaders)
    {
        GLLShaderDescription *descriptor = ownShaders[shaderName];
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

- (void)getShader:(GLLShaderDescription *__autoreleasing *)shader alpha:(BOOL *)shaderIsAlpha forMesh:(NSString *)mesh;
{
    [self getShader:shader alpha:shaderIsAlpha forMeshGroup:[self renderableMeshGroupForMesh:mesh]];
}
- (NSDictionary<NSString *, id> *)renderParametersForMesh:(NSString *)mesh;
{
    if (!ownRenderParameters && model)
    {
        NSMutableDictionary *result = [NSMutableDictionary dictionaryWithDictionary:[self.base renderParametersForMesh:mesh]];
        NSDictionary *forThisMesh = nil;
        [self _parseMeshName:mesh displayName:NULL meshGroup:NULL renderParameters:&forThisMesh cameraTargetName:NULL cameraTargetBones:NULL initiallyVisible:NULL optionalPartNames:NULL];
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

- (GLLShaderDescription *)shaderNamed:(NSString *)name;
{
    GLLShaderDescription *result = [ownShaders objectForKey:name];
    if (!result && self.base)
        return [self.base shaderNamed:name];
    
    return result;
}

- (id)defaultValueForRenderParameter:(NSString *)renderParameter;
{
    id ours = ownDefaultParameters[renderParameter];
    if (!ours)
        return [self.base defaultValueForRenderParameter:renderParameter];
    else
        return ours;
}

- (NSURL *)defaultValueForTexture:(NSString *)textureIdentifier;
{
    id ours = ownDefaultTextures[textureIdentifier];
    if (!ours)
        return [self.base defaultValueForTexture:textureIdentifier];
    else
        return ours;
}

- (NSArray<GLLShaderDescription *> *)allShaders
{
    if (!allShaders) {
        NSArray<GLLShaderDescription *> *own = ownShaders.allValues;
        NSArray<GLLShaderDescription *> *base = self.base.allShaders;
        if (own && base) {
            allShaders = [own arrayByAddingObjectsFromArray:base];
        } else if (own && !base) {
            allShaders = own;
        } else {
            allShaders = base;
        }
    }
    return allShaders;
}

#pragma mark - Render parameter descriptions

- (GLLRenderParameterDescription *)descriptionForParameter:(NSString *)parameterName
{
    GLLRenderParameterDescription *result = ownRenderParameterDescriptions[parameterName];
    if (!result)
    {
        if (self.base) return [self.base descriptionForParameter:parameterName];
        else return nil;
    }
    
    return result;
}

- (GLLTextureDescription *)descriptionForTexture:(NSString *)textureUniformName
{
    GLLTextureDescription *result = ownTextureDescriptions[textureUniformName];
    if (!result)
    {
        if (self.base) return [self.base descriptionForTexture:textureUniformName];
        else return nil;
    }
    
    return result;
}

#pragma mark - Splitting

- (NSArray<NSString *> *)meshesToSplit
{
    if (self.base)
        return [self.base.meshesToSplit arrayByAddingObjectsFromArray:ownMeshSplitters.allKeys];
    else
        if (ownMeshSplitters) return ownMeshSplitters.allKeys;
        else return @[];
}
- (NSArray<GLLMeshSplitter *> *)meshSplittersForMesh:(NSString *)mesh;
{
    NSArray<GLLMeshSplitter *> *result = ownMeshSplitters[mesh];
    if (!result) result = [NSArray array];
    
    if (self.base)
        result = [result arrayByAddingObjectsFromArray:[self.base meshSplittersForMesh:mesh]];
    
    return result;
}

#pragma mark - Optional items
- (BOOL)initiallyVisibleForMesh:(NSString *)mesh {
    BOOL visible = YES;
    [self _parseMeshName:mesh displayName:NULL meshGroup:NULL renderParameters:NULL cameraTargetName:NULL cameraTargetBones:NULL initiallyVisible:&visible optionalPartNames:NULL];
    return visible;
}

- (NSArray<NSString *> *)optionalPartNamesForMesh:(NSString *)mesh {
    NSArray<NSString*> *names = @[];
    [self _parseMeshName:mesh displayName:NULL meshGroup:NULL renderParameters:NULL cameraTargetName:NULL cameraTargetBones:NULL initiallyVisible:NULL optionalPartNames:&names];
    return names;
}

#pragma mark - Equality
- (BOOL)isEqual:(id)object
{
    if (![object isKindOfClass:[self class]]) return NO;
    
    GLLModelParams *param = (GLLModelParams *)object;
#define EQUAL_OR_BOTH_NIL(o) ((o == nil && param->o == nil) || ([o isEqual:param->o]))
    
    return EQUAL_OR_BOTH_NIL(ownCameraTargets) && EQUAL_OR_BOTH_NIL(ownDefaultParameters) && EQUAL_OR_BOTH_NIL(ownDefaultTextures) && EQUAL_OR_BOTH_NIL(ownMeshGroups) && EQUAL_OR_BOTH_NIL(ownMeshSplitters) && EQUAL_OR_BOTH_NIL(ownRenderParameterDescriptions) && EQUAL_OR_BOTH_NIL(ownRenderParameters) && EQUAL_OR_BOTH_NIL(ownShaders) && EQUAL_OR_BOTH_NIL(ownTextureDescriptions);
#undef EQUAL_OR_BOTH_NIL
}

- (NSUInteger)hash
{
    return ownDefaultTextures.hash | ownCameraTargets.hash | ownDefaultParameters.hash | ownMeshGroups.hash | ownMeshSplitters.hash | ownRenderParameterDescriptions.hash | ownRenderParameters.hash | ownShaders.hash | ownTextureDescriptions.hash | model.hash | self.base.hash;
}

#pragma mark - Private methods

- (void)_parseMeshName:(NSString *)meshName displayName:(NSString *__autoreleasing*)displayName meshGroup:(NSString *__autoreleasing *)meshGroup renderParameters:(NSDictionary<NSString *, id> * __autoreleasing*)renderParameters cameraTargetName:(NSString *__autoreleasing*)cameraTargetName cameraTargetBones:(NSArray<NSString *> *__autoreleasing*)cameraTargetBones initiallyVisible:(BOOL * _Nullable )visible optionalPartNames:(NSArray<NSString *> *__autoreleasing _Nullable*)optionalPartNames;
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
        if (visible) {
            *visible = YES;
        }
        if (optionalPartNames) {
            *optionalPartNames = @[];
        }
        return;
    }
    
    // 1st match: mesh group
    // Need this later for render parameters, so this part is always extracted.
    NSString *group = [@"MeshGroup" stringByAppendingString:[meshName substringWithRange:[components rangeAtIndex:1]]];
    if (meshGroup)
        *meshGroup = group;
    
    // 2nd match: mesh name
    if (visible || optionalPartNames || displayName) {
        NSString *namePart = [meshName substringWithRange:[components rangeAtIndex:2]];
        // Parse parts of that for optional item
        if ([namePart hasPrefix:@"+"] || [namePart hasPrefix:@"-"]) {
            if (visible)
                *visible = [namePart hasPrefix:@"+"];
            NSString *remainder = [namePart substringFromIndex:1];
            NSRange firstDot = [remainder rangeOfString:@"."];
            NSString *meshName = @"";
            if (firstDot.location != NSNotFound) {
                // Display name is everything after the dot. This can be an empty
                // string. It can also be a useless string.
                meshName = [remainder substringFromIndex:firstDot.location + 1];
                remainder = [remainder substringToIndex:firstDot.location];
            }
            // Remainder can be empty string here. We accept that.
            NSArray<NSString *> *components = [remainder componentsSeparatedByString:@"|"];
            if (optionalPartNames)
                *optionalPartNames = components;
            if (displayName) {
                if (meshName.length > 0)
                    *displayName = meshName;
                else
                    *displayName = components.lastObject;
            }
        }
        else {
            if (visible)
                *visible = YES;
            if (optionalPartNames)
                *optionalPartNames = @[];
            if (displayName)
                *displayName = namePart;
        }
    }
    
    // 3rd, 4th, 5th match: render parameters
    if (renderParameters)
    {
        GLLShaderDescription *shader;
        [self getShader:&shader alpha:NULL forMeshGroup:group];
        
        NSArray<NSString *> *renderParameterNames = shader.parameterUniformNames;
        
        if (components.numberOfRanges < renderParameterNames.count + 3)
            NSLog(@"Mesh %@ does not have enough render parameters for shader %@ (has %lu, needs %lu). Rest will be set to 0.", meshName, shader.name, renderParameterNames.count, components.numberOfRanges - 3);
        
        NSMutableDictionary<NSString *, id> *renderParameterValues = [[NSMutableDictionary alloc] initWithCapacity:renderParameterNames.count];
        for (NSUInteger i = 0; i < renderParameterNames.count; i++)
        {
            // Find the value
            NSNumber *value = @0.0;
            if (components.numberOfRanges >= i + 3 && [components rangeAtIndex:i+3].location != NSNotFound) {
                NSString *stringValue = [meshName substringWithRange:[components rangeAtIndex:3 + i]];
                value = [englishNumberFormatter numberFromString:stringValue];
            }
            
            // One entry can map to multiple parameters. Easiest if we just turn everything into an array.
            id parameterName = renderParameterNames[i];
            NSArray *allNames;
            if ([parameterName isKindOfClass:[NSArray class]]) {
                allNames = parameterName;
            } else {
                allNames = @[parameterName];
            }
            
            // Assign
            for (id name in allNames) {
                renderParameterValues[name] = value;
            }
        }
        
        *renderParameters = [renderParameterValues copy];
    }
    
    // 6th match: Camera name
    if (cameraTargetName)
    {
        if (components.numberOfRanges <= 6 || [components rangeAtIndex:6].location == NSNotFound)
            *cameraTargetName = nil;
        else
            *cameraTargetName = [meshName substringWithRange:[components rangeAtIndex:6]];
    }
    
    // Final matches: Camera bones
    if (cameraTargetBones)
    {
        if (components.numberOfRanges <= 7 || [components rangeAtIndex:7].location == NSNotFound)
        {
            *cameraTargetBones = nil;
        }
        else
        {
            NSMutableArray<NSString *> *bones = [[NSMutableArray alloc] initWithCapacity:components.numberOfRanges - 7];
            for (NSUInteger i = 7; i < components.numberOfRanges; i++)
                [bones addObject:[meshName substringWithRange:[components rangeAtIndex:i]]];
            *cameraTargetBones = [bones copy];
        }
    }
}

@end
