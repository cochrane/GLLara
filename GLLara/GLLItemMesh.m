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
#import "GLLRenderParameter.h"
#import "NSArray+Map.h"

#import "GLLara-Swift.h"

@interface GLLItemMesh ()

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
    
    // Set display name
    self.displayName = self.mesh.displayName;
    
    GLLShaderData *modelShaderData = self.mesh.shader;
    self.shaderBase = modelShaderData.base.name;
    for (GLLShaderModule *module in modelShaderData.activeModules) {
        [self setIncluded:YES forShaderModule:module.name];
    }
    
    // Set the initial rendering values
    [self updateShader];
    
    [self _setupObservingForShaderChanges];
}

- (void)awakeFromFetch
{
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
    
    [self updateShader];
    
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
        NSManagedObject *firstFound = nil;
        for (NSManagedObject *nameHolder in shaderFeatures) {
            if ([[nameHolder valueForKey:@"name"] isEqual:module]) {
                firstFound = nameHolder;
            }
        }
        if (firstFound) {
            [shaderFeatures removeObject:firstFound];
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
    NSDictionary *values = self.mesh.renderParameterValues;
    
    // Set up render parameters that do not exist yet
    for (NSString *renderParameterName in shaderDescription.parameterUniforms)
    {
        if (![self renderParameterWithName:renderParameterName])
        {
            GLLRenderParameterDescription *description = [shaderDescription descriptionForParameter:renderParameterName];
            
            GLLRenderParameter *parameter;
            
            if (description.type == GLLRenderParameterTypeFloat) {
                parameter = [NSEntityDescription insertNewObjectForEntityForName:@"GLLFloatRenderParameter" inManagedObjectContext:self.managedObjectContext];
                [parameter setValue:[NSNumber numberWithDouble:[params defaultValueForRenderParameter:renderParameterName]] forKey:@"value"];
            } else if (description.type == GLLRenderParameterTypeColor) {
                parameter = [NSEntityDescription insertNewObjectForEntityForName:@"GLLColorRenderParameter" inManagedObjectContext:self.managedObjectContext];
                [parameter setValue:[params defaultColorForRenderParameter:renderParameterName] forKey:@"value"];
            } else
                continue; // Skip this param
            
            // Check if we have mesh-specific value for this
            if (values[renderParameterName]) {
                [parameter setValue:values[renderParameterName] forKey:@"value"];
            }
            
            // Special case: bumpSpecularAmount gets mapped to specularColor
            if (description.type == GLLRenderParameterTypeColor && [renderParameterName isEqual:@"specularColor"]) {
                double scalar = 1.0;
                GLLRenderParameter* scalarParameter = [self renderParameterWithName:@"bumpSpecularAmount"];
                if (scalarParameter) {
                    scalar = [[scalarParameter valueForKey:@"value"] doubleValue];
                    [[self mutableSetValueForKey:@"renderParameters"] removeObject:scalarParameter];
                    [self.managedObjectContext deleteObject:scalarParameter];
                }
                else if (values[@"bumpSpecularAmount"]) {
                    scalar = [values[@"bumpSpecularAmount"] doubleValue];
                }
                
                NSColor *colorParameterValue = [parameter valueForKey:@"value"];
                CGFloat red, green, blue, alpha;
                [[colorParameterValue colorUsingColorSpace:[NSColorSpace genericRGBColorSpace]] getRed:&red green:&green blue:&blue alpha:&alpha];
                
                NSColor *result = [NSColor colorWithRed:red * scalar green:green * scalar blue:blue * scalar alpha:alpha];
                [parameter setValue:result forKey:@"value"];
            }
            
            parameter.name = renderParameterName;
            parameter.mesh = self;
        }
    }
    
    // Set up textures that do not exist yet.
    for (NSString *textureName in shaderDescription.textureUniforms)
    {
        if (![self textureWithIdentifier:textureName])
        {
            GLLItemMeshTexture *texture = [NSEntityDescription insertNewObjectForEntityForName:@"GLLItemMeshTexture" inManagedObjectContext:self.managedObjectContext];
            texture.mesh = self;
            texture.identifier = textureName;
            GLLTextureAssignment *textureAssignment = self.mesh.textures[textureName];
            if (!textureAssignment) {
                // Don't have assignment, either because we changed to new shader or because original model was defective
                // Use default.
                texture.textureURL = [self.mesh.model.parameters defaultValueForTexture:texture.identifier];
                NSNumber *texCoordAssignmentInShader = self.mesh.shader.texCoordAssignments[texture.identifier];
                texture.texCoordSet = texCoordAssignmentInShader ? texCoordAssignmentInShader.integerValue : 0;
            } else {
                texture.textureURL = textureAssignment.url;
                texture.texCoordSet = textureAssignment.texCoordSet;
            }
        }
    }
    
    [self willChangeValueForKey:@"shader"];
    self.shader = shaderDescription;
    [self didChangeValueForKey:@"shader"];
}

#pragma mark - Derived

- (NSUInteger)meshIndex
{
    return [self.item.meshes indexOfObject:self];
}

#pragma mark - Private

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
