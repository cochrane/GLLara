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
#import "GLLModelParams.h"
#import "GLLRenderParameter.h"
#import "NSArray+Map.h"

#import "GLLara-Swift.h"

@interface GLLItemMesh ()
{
    __weak GLLModelMesh *underlyingMesh;
}

- (void)_createTextureAndShaderAssignments;

@end

@implementation GLLItemMesh

@dynamic cullFaceMode;
@dynamic isBlended;
@dynamic isCustomBlending;
@dynamic isVisible;
@dynamic item;
@dynamic renderParameters;
@dynamic shaderName;
@dynamic textures;

@dynamic mesh;
@dynamic meshIndex;
@dynamic displayName;
@dynamic isUsingBlending;

+ (NSSet *)keyPathsForValuesAffectingIsUsingBlending
{
    return [NSSet setWithObjects:@"isBlended", @"isCustomBlending", nil];
}

- (void)prepareGraphicsData;
{
    // Replace all render parameters
    NSDictionary *values = self.mesh.renderParameterValues;
    NSMutableSet *renderParameters = [self mutableSetValueForKey:@"renderParameters"];
    [renderParameters removeAllObjects];
    for (NSString *uniformName in self.mesh.shader.allUniformNames)
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
    
    [self _createTextureAndShaderAssignments];
}

- (void)awakeFromFetch
{
    NSMutableSet *textures = [self mutableSetValueForKey:@"textures"];
    if (textures.count == 0 || self.shaderName == nil)
        [self _createTextureAndShaderAssignments];
    
    if (!self.displayName)
        self.displayName = self.mesh.displayName;
}

#pragma mark - Shader changes

- (void)setShaderName:(NSString *)shaderName
{
    GLLModelParams *params = self.mesh.model.parameters;
    GLLShaderDescription *shaderDescription = [params shaderNamed:shaderName];
    if (!shaderDescription)
    {
        [self willChangeValueForKey:@"shaderName"];
        [self setPrimitiveValue:nil forKey:@"shaderName"];
        [self didChangeValueForKey:@"shaderName"];
        return;
    }
    
    [self willChangeValueForKey:@"shaderName"];
    [self setPrimitiveValue:shaderName forKey:@"shaderName"];
    [self didChangeValueForKey:@"shaderName"];
    
    // Set up render parameters that do not exist yet
    for (NSString *renderParameterName in shaderDescription.parameterUniformNames)
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
            [parameter setValue:[params defaultValueForRenderParameter:renderParameterName] forKey:@"value"];
            parameter.mesh = self;
        }
    }
    
    // Set up textures that do not exist yet.
    for (NSString *textureName in shaderDescription.textureUniformNames)
    {
        if (![self textureWithIdentifier:textureName])
        {
            GLLItemMeshTexture *texture = [NSEntityDescription insertNewObjectForEntityForName:@"GLLItemMeshTexture" inManagedObjectContext:self.managedObjectContext];
            texture.identifier = textureName;
            texture.textureURL = [params defaultValueForTexture:textureName];
            texture.mesh = self;
        }
    }
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

- (GLLShaderDescription *)shader
{
    return [self.mesh.model.parameters shaderNamed:self.shaderName];
}

- (void)setShader:(GLLShaderDescription *)shader
{
    self.shaderName = shader.name;
}

- (NSArray<GLLShaderDescription *> *)possibleShaderDescriptions
{
    return self.mesh.model.parameters.allShaders;
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

- (void)_createTextureAndShaderAssignments;
{
    // Replace all textures
    NSMutableSet *textures = [self mutableSetValueForKey:@"textures"];
    [textures removeAllObjects];
    for (NSUInteger i = 0; i < self.mesh.shader.textureUniformNames.count; i++)
    {
        GLLItemMeshTexture *texture = [NSEntityDescription insertNewObjectForEntityForName:@"GLLItemMeshTexture" inManagedObjectContext:self.managedObjectContext];
        texture.mesh = self;
        texture.identifier = self.mesh.shader.textureUniformNames[i];
        if (i >= self.mesh.textures.count) {
            // Grrr, idiot forgot to set texture that the shader is clearly
            // using. Need to use some default.
            texture.textureURL = [self.mesh.model.parameters defaultValueForTexture:texture.identifier];
        } else {
            texture.textureURL = self.mesh.textures[i];
        }
    }
    
    // Find shader value
    self.shaderName = self.mesh.shader.name;
}

@end
