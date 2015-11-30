//
//  GLLItemMeshTextureSelectionPlaceholder.m
//  GLLara
//
//  Created by Torsten Kammer on 29.11.15.
//  Copyright (c) 2015 Torsten Kammer. All rights reserved.
//

#import "GLLItemMeshTextureSelectionPlaceholder.h"

#import "GLLItemMesh.h"
#import "GLLItemMeshTexture.h"

@interface GLLItemMeshTextureSelectionPlaceholder ()

@property (nonatomic, copy) NSString *textureName;
@property (nonatomic, copy) NSString *keyPath;

@end

@implementation GLLItemMeshTextureSelectionPlaceholder

- (instancetype)initWithTextureName:(NSString *)textureName keyPath:(NSString *)keyPath selection:(GLLSelection *)selection;
{
    NSParameterAssert(textureName);
    NSParameterAssert(keyPath);
    
    if (!(self = [super initWithSelection:selection typeKey:@"selectedMeshes"]))
        return nil;
    
    _textureName = textureName;
    _keyPath = keyPath;
    
    [self update];
    
    return self;
}

- (id)valueFrom:(GLLItemMesh *)sourceObject {
    GLLItemMeshTexture *texture = [sourceObject textureWithIdentifier:self.textureName];
    return [texture valueForKeyPath:self.keyPath];
}

- (void)setValue:(id)value onSourceObject:(GLLItemMesh *)object {
    GLLItemMeshTexture *texture = [object textureWithIdentifier:self.textureName];
    [texture setValue:value forKeyPath:self.keyPath];
}

@end
