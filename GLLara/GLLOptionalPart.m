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

@interface GLLOptionalPart() {
    // Whether all meshes are invisible at the start. If yes, it's simply an
    // inactive part and the meshes get treated normally (visibility = our
    // visibility). Otherwise meshes starting with a "-" are alternate meshes,
    // to be shown when the part is turned off.
    BOOL initiallyAllInvisible;
}

@end

@implementation GLLOptionalPart

@dynamic visible;

- (id)initWithItem:(GLLItem *)item name:(NSString *)name {
    if (!(self = [super init]))
        return nil;
    
    _item = item;
    _name = name;
    
    BOOL haveVisibles = NO;
    BOOL haveInvisibles = NO;
    for (GLLItemMesh *mesh in item.meshes) {
        if ([mesh.displayName hasPrefix:[NSString stringWithFormat:@"-%@", self.name]]) {
            // Invisible for this item
            [mesh addObserver:self forKeyPath:@"isVisible" options:0 context:NULL];
            haveInvisibles = haveInvisibles || YES;
        } else if ([mesh.displayName hasPrefix:[NSString stringWithFormat:@"+%@", self.name]]) {
            // Visible for this item
            [mesh addObserver:self forKeyPath:@"isVisible" options:0 context:NULL];
            haveVisibles = haveVisibles || YES;
        }
    }
    if (haveInvisibles && !haveVisibles) {
        initiallyAllInvisible = YES;
    }
    
    return self;
}

- (void)dealloc {
    for (GLLItemMesh *mesh in _item.meshes) {
        [mesh removeObserver:self forKeyPath:@"isVisible"];
    }
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
        if ([mesh.displayName hasPrefix:[NSString stringWithFormat:@"-%@", self.name]]) {
            if (initiallyAllInvisible) {
                // Supposed to be visible for this item
                foundActive = foundActive || mesh.isVisible;
                foundInactive = foundInactive || !mesh.isVisible;
            } else {
                // Supposed to be invisible for this item
                foundActive = foundActive || !mesh.isVisible;
                foundInactive = foundInactive || mesh.isVisible;
            }
        } else if ([mesh.displayName hasPrefix:[NSString stringWithFormat:@"+%@", self.name]]) {
            // Supposed to be visible for this item
            foundActive = foundActive || mesh.isVisible;
            foundInactive = foundInactive || !mesh.isVisible;
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
        if ([mesh.displayName hasPrefix:[NSString stringWithFormat:@"-%@", self.name]]) {
            if (initiallyAllInvisible) {
                // Visible for this item
                mesh.isVisible = [visible boolValue];
            } else {
                // Invisible for this item
                mesh.isVisible = ![visible boolValue];
            }
        } else if ([mesh.displayName hasPrefix:[NSString stringWithFormat:@"+%@", self.name]]) {
            // Visible for this item
            mesh.isVisible = [visible boolValue];
        }
    }
    [self didChangeValueForKey:@"visible"];
}

@end
