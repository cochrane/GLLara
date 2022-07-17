//
//  GLLOptionalPart.m
//  GLLara
//
//  Created by Torsten Kammer on 19.04.18.
//  Copyright © 2018 Torsten Kammer. All rights reserved.
//

#import "GLLOptionalPart.h"

#import "GLLItem.h"
#import "GLLItemMesh.h"

#import "GLLara-Swift.h"

@interface GLLOptionalPart() {
    // Whether all meshes are invisible at the start. If yes, it's simply an
    // inactive part and the meshes get treated normally (visibility = our
    // visibility). Otherwise meshes starting with a "-" are alternate meshes,
    // to be shown when the part is turned off.
    BOOL initiallyAllInvisible;
    
    NSArray<GLLItemMesh*>* meshes;
}

- (void)recalculateInitialVisibility;

// Called during init by child on parent
- (void)addChild:(GLLOptionalPart *_Nonnull)child;

// Checks whether the mesh belongs to this part.
- (BOOL)containsMesh:(GLLItemMesh *)mesh;

@end

@implementation GLLOptionalPart

@dynamic visible;

- (id)initWithItem:(GLLItem *)item name:(NSString *)name parent:(GLLOptionalPart *_Nullable)parent {
    if (!(self = [super init]))
        return nil;
    
    _item = item;
    _name = name;
    _parent = parent;
    _children = [NSMutableArray array];
    
    NSMutableArray<GLLItemMesh*> *mutableMeshes = [[NSMutableArray alloc] init];
    for (GLLItemMesh *mesh in self.item.meshes) {
        if ([self containsMesh:mesh]) {
            [mutableMeshes addObject:mesh];
        }
    }
    meshes = [mutableMeshes copy];
    
    [self recalculateInitialVisibility];
    if (parent)
        [parent addChild:self];
    
    
    return self;
}

- (void)recalculateInitialVisibility; {
    BOOL haveVisibles = NO;
    BOOL haveInvisibles = NO;
    for (GLLItemMesh *mesh in meshes) {
        haveInvisibles = haveInvisibles || !mesh.mesh.initiallyVisible;
        haveVisibles = haveVisibles || mesh.mesh.initiallyVisible;
        [mesh addObserver:self forKeyPath:@"isVisible" options:0 context:NULL];
    }
    for (GLLOptionalPart *child in self.children) {
        if (child.visible == NSBindingSelectionMarker.multipleValuesSelectionMarker) {
            haveInvisibles = YES;
            haveVisibles = YES;
            break;
        } else if ([child.visible boolValue]) {
            haveVisibles = YES;
        } else if (![child.visible boolValue]) {
            haveInvisibles = YES;
        }
    }
    if (haveInvisibles && !haveVisibles) {
        initiallyAllInvisible = YES;
    }
}

- (void)dealloc {
    for (GLLItemMesh *mesh in meshes) {
        [mesh removeObserver:self forKeyPath:@"isVisible"];
    }
    for (GLLOptionalPart *child in _children) {
        [child removeObserver:self forKeyPath:@"visible"];
    }
}

- (void)addChild:(GLLOptionalPart *_Nonnull)child {
    [(NSMutableArray *) _children addObject:child];
    [self recalculateInitialVisibility];
    [child addObserver:self forKeyPath:@"visible" options:NSKeyValueObservingOptionNew context:NULL];
}

- (GLLOptionalPart *)childWithName:(NSString *)name {
    for (GLLOptionalPart *part in self.children) {
        if ([part.name isEqualToString:name])
            return part;
    }
    return nil;
}

- (BOOL)hasNoChildren {
    return [self numberOfChildren] == 0;
}

- (NSUInteger)numberOfChildren {
    return self.children.count;
}

- (void)observeValueForKeyPath:(NSString *)keyPath ofObject:(id)object change:(NSDictionary<NSKeyValueChangeKey,id> *)change context:(void *)context {
    if ([keyPath isEqual:@"isVisible"] || [keyPath isEqual:@"visible"]) {
        [self willChangeValueForKey:@"visible"];
        [self didChangeValueForKey:@"visible"];
    } else {
        [super observeValueForKeyPath:keyPath ofObject:object change:change context:context];
    }
}

- (id)visible {
    BOOL foundActive = NO;
    BOOL foundInactive = NO;
    for (GLLItemMesh *mesh in meshes) {
        if (mesh.mesh.initiallyVisible || initiallyAllInvisible) {
            // Supposed to be visible for this item
            foundActive = foundActive || mesh.isVisible;
            foundInactive = foundInactive || !mesh.isVisible;
        } else {
            // Supposed to be invisible for this item
            foundActive = foundActive || !mesh.isVisible;
            foundInactive = foundInactive || mesh.isVisible;
        }
        
        if (foundActive && foundInactive)
            return NSBindingSelectionMarker.multipleValuesSelectionMarker;
    }
    for (GLLOptionalPart *child in self.children) {
        if (child.visible == NSBindingSelectionMarker.multipleValuesSelectionMarker)
            return NSBindingSelectionMarker.multipleValuesSelectionMarker;
        else if ([child.visible boolValue])
            foundActive = YES;
        else if (![child.visible boolValue])
            foundInactive = YES;
        
        if (foundActive && foundInactive)
            return NSBindingSelectionMarker.multipleValuesSelectionMarker;
    }
    if (foundActive)
        return @(YES);
    return @(NO);
}

- (void)setVisible:(id)visible {
    if (visible == NSBindingSelectionMarker.multipleValuesSelectionMarker) {
        return;
    }
    
    [self willChangeValueForKey:@"visible"];
    for (GLLItemMesh *mesh in meshes) {
        if (initiallyAllInvisible || mesh.mesh.initiallyVisible) {
            // Visible for this item
            mesh.isVisible = [visible boolValue];
        } else {
            // Invisible for this item
            mesh.isVisible = ![visible boolValue];
        }
    }
    for (GLLOptionalPart *child in self.children) {
        child.visible = visible;
    }
    [self didChangeValueForKey:@"visible"];
}

- (BOOL)containsMesh:(GLLItemMesh *)mesh {
    NSArray<NSString *> *nameParts = mesh.mesh.optionalPartNames;
    if (nameParts.count == 0)
        return NO;
    
    NSMutableArray<NSString *> *ownNameParts = [NSMutableArray array];
    GLLOptionalPart *part = self;
    while (part) {
        [ownNameParts insertObject:part.name atIndex:0];
        part = part.parent;
    }
    
    if (ownNameParts.count != nameParts.count) {
        // Not part of self, but of either parent or child.
        return NO;
    }
    
    for (NSUInteger i = 0; i < ownNameParts.count; i++) {
        if (i >= nameParts.count) {
            return NO; // Part of some prefix of this item
        }
        if (![ownNameParts[i] isEqualToString:nameParts[i]]) {
            return NO;
        }
    }
    return YES;
}

@end
