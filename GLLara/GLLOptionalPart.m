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
#import "GLLModelMesh.h"

@interface GLLOptionalPart() {
    // Whether all meshes are invisible at the start. If yes, it's simply an
    // inactive part and the meshes get treated normally (visibility = our
    // visibility). Otherwise meshes starting with a "-" are alternate meshes,
    // to be shown when the part is turned off.
    BOOL initiallyAllInvisible;
}

// Called during init by child on parent
- (void)addChild:(GLLOptionalPart *_Nonnull)child;

// Checks whether the mesh belongs to this part.
- (BOOL)meshBelongsToThisPart:(GLLItemMesh *)mesh;

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
    
    BOOL haveVisibles = NO;
    BOOL haveInvisibles = NO;
    for (GLLItemMesh *mesh in item.meshes) {
        if (![self meshBelongsToThisPart:mesh]) {
            continue;
        }
        haveInvisibles = haveInvisibles || !mesh.mesh.initiallyVisible;
        haveVisibles = haveVisibles || mesh.mesh.initiallyVisible;
        [mesh addObserver:self forKeyPath:@"isVisible" options:0 context:NULL];
    }
    if (haveInvisibles && !haveVisibles) {
        initiallyAllInvisible = YES;
    }
    if (parent)
        [parent addChild:self];
    
    return self;
}

- (void)dealloc {
    for (GLLItemMesh *mesh in _item.meshes) {
        if ([self meshBelongsToThisPart:mesh])
            [mesh removeObserver:self forKeyPath:@"isVisible"];
    }
}

- (void)addChild:(GLLOptionalPart *_Nonnull)child {
    [(NSMutableArray *) _children addObject:child];
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
    if ([keyPath isEqual:@"isVisible"]) {
        [self willChangeValueForKey:@"visible"];
        [self didChangeValueForKey:@"visible"];
    } else {
        [super observeValueForKeyPath:keyPath ofObject:object change:change context:context];
    }
}

- (id)isVisible {
    BOOL foundActive = NO;
    BOOL foundInactive = NO;
    for (GLLItemMesh *mesh in self.item.meshes) {
        if (![self meshBelongsToThisPart:mesh]) {
            continue;
        }
        
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
            return NSMultipleValuesMarker;
    }
    if (foundActive)
        return @(YES);
    return @(NO);
}

- (void)setVisible:(id)visible {
    if (visible == NSMultipleValuesMarker) {
        return;
    }
    
    [self willChangeValueForKey:@"visible"];
    for (GLLItemMesh *mesh in self.item.meshes) {
        if (![self meshBelongsToThisPart:mesh]) {
            continue;
        }
        
        if (initiallyAllInvisible || mesh.mesh.initiallyVisible) {
            // Visible for this item
            mesh.isVisible = [visible boolValue];
        } else {
            // Invisible for this item
            mesh.isVisible = ![visible boolValue];
        }
    }
    [self didChangeValueForKey:@"visible"];
}

- (BOOL)meshBelongsToThisPart:(GLLItemMesh *)mesh {
    // Go in reverse through our hierarchy and mesh names, matching each
    // element. If anything doesn't match or they don't have the same length,
    // return false.
    NSArray<NSString *> *nameParts = mesh.mesh.optionalPartNames;
    if (nameParts.count == 0)
        return NO;
    
    NSInteger i = nameParts.count - 1;
    GLLOptionalPart *currentPart = self;
    while (i >= 0) {
        if (!currentPart) {
            // Array of target mesh is too long
            return NO;
        }
        
        if (![currentPart.name isEqualToString:nameParts[i]]) {
            return NO;
        }
        i -= 1;
        
        currentPart = currentPart.parent;
    }
    
    // Array of target mesh might be shorter, but that's okay.
    
    return YES;
}

@end
