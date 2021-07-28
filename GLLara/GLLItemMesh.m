//
//  GLLItemMesh.m
//  GLLara
//
//  Created by Torsten Kammer on 05.09.12.
//  Copyright (c) 2012 Torsten Kammer. All rights reserved.
//

#import "GLLItemMesh.h"

#import <AppKit/NSKeyValueBinding.h>

#import "GLLItem.h"
#import "GLLItemMeshTexture.h"
#import "GLLModel.h"
#import "GLLModelMesh.h"
#import "GLLRenderParameter.h"
#import "NSArray+Map.h"

#import "GLLara-Swift.h"

@interface GLLItemMesh ()
{
    __weak GLLModelMesh *underlyingMesh;
}

@property (nonatomic, retain, readwrite) GLLShaderData *shader;

/*!
 * Assign the textures from the model to this item.
 * Used when creating this object, or when loading a (very) old file that was
 * created before we had the texture assignments.
 */
- (void)_assignTexturesFromModel;

/*!
 * Creates the GLLShaderData object for this mesh, given the current values.
 */
- (GLLShaderData *)_createShaderData;

/*!
 * Called on loading or creating. Sets up all necessery KVO observing to make
 * sure we update the shader when we need to.
 */
- (void)_setupObservingForShaderChanges;

@end

@implementation GLLItemMesh

@dynamic cullFaceMode;
@dynamic isBlended;
@dynamic isCustomBlending;
@dynamic isVisible;
@dynamic item;
@dynamic renderParameters;
@dynamic shaderBase;
@dynamic textures;

@dynamic mesh;
@dynamic meshIndex;
@dynamic displayName;
@dynamic isUsingBlending;

@synthesize shader;

+ (NSSet *)keyPathsForValuesAffectingIsUsingBlending
{
    return [NSSet setWithObjects:@"isBlended", @"isCustomBlending", nil];
}

- (void)prepareWithItem:(GLLItem *)item;
{
    self.item = item;
    
    self.cullFaceMode = self.mesh.cullFaceMode;
    self.isVisible = self.mesh.initiallyVisible;
    
    // Set the initial render parameter values
    NSDictionary *values = self.mesh.renderParameterValues;
    NSMutableSet *renderParameters = [self mutableSetValueForKey:@"renderParameters"];
    [renderParameters removeAllObjects];
    for (NSString *uniformName in self.mesh.shader.parameterUniforms)
    {
        GLLRenderParameterDescription *description = [self.mesh.shader descriptionForParameter:uniformName];
        
        GLLRenderParameter *parameter;
        
        if (description.type == GLLRenderParameterTypeFloat)
            parameter = [NSEntityDescription insertNewObjectForEntityForName:@"GLLFloatRenderParameter" inManagedObjectContext:self.managedObjectContext];
        else if (description.type == GLLRenderParameterTypeColor)
            parameter = [NSEntityDescription insertNewObjectForEntityForName:@"GLLColorRenderParameter" inManagedObjectContext:self.managedObjectContext];
        else
            continue; // Skip this param
        
        if (values[uniformName] == nil) {
            NSLog(@"Have no value for %@", uniformName);
        }
        
        parameter.name = uniformName;
        [parameter setValue:values[uniformName] forKey:@"value"];
        
        [renderParameters addObject:parameter];
    }
    
    // Set display name
    self.displayName = self.mesh.displayName;
    
    // Set the textures
    [self _assignTexturesFromModel];
    
    GLLShaderData *modelShaderData = self.mesh.shader;
    self.shaderBase = modelShaderData.base.name;
    for (NSString *moduleName in modelShaderData.activeModules) {
        [self setIncluded:YES forShaderModule:moduleName];
    }
    
    [self _setupObservingForShaderChanges];
}

- (void)awakeFromFetch
{
    NSMutableSet *textures = [self mutableSetValueForKey:@"textures"];
    
    // No textures? This may be an old scene file from before when textures got
    // stored in the database. Try loading the texture assignments from the
    // model file.
    if (textures.count == 0)
        [self _assignTexturesFromModel];
    
    if (self.shaderBase == nil) {
        // Old file, migrate to new format
        NSString *shaderName = [self valueForKey:@"shaderName"];
        if (shaderName) {
            GLLModelParams *params = [GLLModelParams parametersForName:@"lara" error:NULL];
            NSAssert(params != nil, @"Need to have base params");
            XnaLaraShaderDescription *xnaLaraDescription = [params xnaLaraShaderDescriptionWithName:shaderName];
            if (xnaLaraDescription) {
                self.shaderBase = xnaLaraDescription.baseName;
                for (NSString *feature in xnaLaraDescription.moduleNames) {
                    [self setIncluded:YES forShaderModule:feature];
                }
                // Assign the texture coordinates
                for (GLLItemMeshTexture *texture in self.textures) {
                    texture.texCoordSet = [xnaLaraDescription texCoordSetFor: texture.identifier];
                }
            }
            [self setValue:nil forKey:@"shaderName"];
        }
    }
    
    if (!self.displayName)
        self.displayName = self.mesh.displayName;
    
    [self _setupObservingForShaderChanges];
}

- (NSSet<NSString *> *)shaderModules {
    NSMutableSet *names = [[NSMutableSet alloc] init];
    for (NSManagedObject *nameHolder in [self mutableSetValueForKey:@"shaderFeatures"]) {
        [names addObject:[nameHolder valueForKey:@"name"]];
    }
    return names;
}

- (void)setIncluded:(BOOL)included forShaderModule:(NSString *)module {
    if (included == [self isShaderModuleIncluded:module]) {
        return;
    }
    NSMutableSet *shaderFeatures = [self mutableSetValueForKey:@"shaderFeatures"];
    if (included) {
        NSManagedObject *nameHolder = [NSEntityDescription insertNewObjectForEntityForName:@"GLLShaderFeature" inManagedObjectContext:self.managedObjectContext];
        [nameHolder setValue:module forKey:@"name"];
        [shaderFeatures addObject:nameHolder];
    } else {
        for (NSManagedObject *nameHolder in shaderFeatures) {
            if ([[nameHolder valueForKey:@"name"] isEqual:module]) {
                [shaderFeatures removeObject:nameHolder];
            }
        }
    }
}

- (BOOL)isShaderModuleIncluded:(NSString *)module {
    for (NSManagedObject *nameHolder in [self mutableSetValueForKey:@"shaderFeatures"]) {
        if ([[nameHolder valueForKey:@"name"] isEqual:module]) {
            return YES;
        }
    }
    return NO;
}

#pragma mark - Shader changes

- (void)_setupObservingForShaderChanges {
    [self addObserver:self forKeyPath:@"shaderBase" options:0 context:NULL];
    [self addObserver:self forKeyPath:@"shaderFeatures" options:0 context:NULL];
    
    [self updateShader];
}

- (void)dealloc {
    [self removeObserver:self forKeyPath:@"shaderBase"];
    [self removeObserver:self forKeyPath:@"shaderFeatures"];
}

- (void)observeValueForKeyPath:(NSString *)keyPath ofObject:(id)object change:(NSDictionary<NSKeyValueChangeKey,id> *)change context:(void *)context {
    if (([keyPath isEqual:@"shaderBase"] || [keyPath isEqual:@"shaderFeatures"]) && context == NULL) {
        [self updateShader];
    } else {
        [super observeValueForKeyPath:keyPath ofObject:object change:change context:context];
    }
}

- (void)updateShader {
    GLLShaderData *shaderDescription = [self _createShaderData];
    if (!shaderDescription) {
        self.shader = shaderDescription;
        return;
    }
    
    GLLModelParams *params = self.mesh.model.parameters;
    
    // Set up render parameters that do not exist yet
    for (NSString *renderParameterName in shaderDescription.parameterUniforms)
    {
        if (![self renderParameterWithName:renderParameterName])
        {
            GLLRenderParameterDescription *description = [shaderDescription descriptionForParameter:renderParameterName];
            
            GLLRenderParameter *parameter;
            
            if (description.type == GLLRenderParameterTypeFloat)
                parameter = [NSEntityDescription insertNewObjectForEntityForName:@"GLLFloatRenderParameter" inManagedObjectContext:self.managedObjectContext];
            else if (description.type == GLLRenderParameterTypeColor)
                parameter = [NSEntityDescription insertNewObjectForEntityForName:@"GLLColorRenderParameter" inManagedObjectContext:self.managedObjectContext];
            else
                continue; // Skip this param
            
            parameter.name = renderParameterName;
            [parameter setValue:[NSNumber numberWithDouble:[params defaultValueForRenderParameter:renderParameterName]] forKey:@"value"];
            parameter.mesh = self;
        }
    }
    
    // Set up textures that do not exist yet.
    for (NSString *textureName in shaderDescription.textureUniforms)
    {
        if (![self textureWithIdentifier:textureName])
        {
            GLLItemMeshTexture *texture = [NSEntityDescription insertNewObjectForEntityForName:@"GLLItemMeshTexture" inManagedObjectContext:self.managedObjectContext];
            texture.identifier = textureName;
            texture.textureURL = [params defaultValueForTexture:textureName];
            texture.texCoordSet = 0;
            texture.mesh = self;
        }
    }
    
    self.shader = shaderDescription;
}

#pragma mark - Derived

- (NSUInteger)meshIndex
{
    return [self.item.meshes indexOfObject:self];
}

- (GLLModelMesh *)mesh
{
    if (!underlyingMesh)
        underlyingMesh = self.item.model.meshes[self.meshIndex];
    return underlyingMesh;
}

- (GLLRenderParameter *)renderParameterWithName:(NSString *)parameterName;
{
    return [self.renderParameters anyObjectMatching:^BOOL(GLLRenderParameter *parameter){
        return [parameter.name isEqual:parameterName];
    }];
}
- (GLLItemMeshTexture *)textureWithIdentifier:(NSString *)textureIdentifier;
{
    return [self.textures anyObjectMatching:^BOOL(GLLItemMeshTexture *texture){
        return [texture.identifier isEqual:textureIdentifier];
    }];
}

- (BOOL)isUsingBlending
{
    if (self.isCustomBlending)
        return self.isBlended;
    else
        return self.mesh.usesAlphaBlending;
}

- (void)setIsUsingBlending:(BOOL)isUsingBlending
{
    self.isCustomBlending = YES;
    self.isBlended = isUsingBlending;
}

#pragma mark - Private

- (void)_assignTexturesFromModel;
{
    // Replace all textures
    NSMutableSet<GLLItemMeshTexture *> *textures = [self mutableSetValueForKey:@"textures"];
    [textures removeAllObjects];
    for (NSString *identifier in self.mesh.shader.textureUniforms)
    {
        GLLItemMeshTexture *texture = [NSEntityDescription insertNewObjectForEntityForName:@"GLLItemMeshTexture" inManagedObjectContext:self.managedObjectContext];
        texture.mesh = self;
        texture.identifier = identifier;
        GLLTextureAssignment *textureAssignment = self.mesh.textures[identifier];
        if (!textureAssignment) {
            // Grrr, idiot forgot to set texture that the shader is clearly
            // using. Need to use some default.
            texture.textureURL = [self.mesh.model.parameters defaultValueForTexture:texture.identifier];
            NSNumber *texCoordAssignmentInShader = self.mesh.shader.texCoordAssignments[texture.identifier];
            texture.texCoordSet = texCoordAssignmentInShader ? texCoordAssignmentInShader.integerValue : 0;
        } else {
            texture.textureURL = textureAssignment.url;
            texture.texCoordSet = textureAssignment.texCoordSet;
        }
    }
}

- (GLLShaderData *)_createShaderData {
    // Find the shader data object for this item based on active features and assigned tex coord sets
    NSArray<NSString *>* activeModules = [[self mutableSetValueForKey:@"shaderFeatures"] map:^NSString *(NSManagedObject *object) {
        return [object valueForKey:@"name"];
    }];
    NSMutableDictionary *texCoordSets = [[NSMutableDictionary alloc] init];
    for (GLLItemMeshTexture *assignment in [self valueForKeyPath:@"textures"]) {
        texCoordSets[assignment.identifier] = @(assignment.texCoordSet);
    }
    
    return [self.mesh.model.parameters explicitShaderWithBase:self.shaderBase modules:activeModules texCoordAssignments: texCoordSets alphaBlending: self.isUsingBlending];
}

@end
