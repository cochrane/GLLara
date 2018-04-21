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
    BOOL updating;
}

- (BOOL)meshIsRelevant:(GLLItemMesh *)mesh;

@end

@implementation GLLOptionalPart

@dynamic visible;

- (id)initWithItem:(GLLItem *)item name:(NSString *)name {
    if (!(self = [super init]))
        return nil;
    
    _item = item;
    _name = name;
    
    for (GLLItemMesh *mesh in item.meshes) {
        if ([self meshIsRelevant:mesh]) {
            [mesh addObserver:self forKeyPath:@"isVisible" options:0 context:NULL];
        }
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
        if (updating)
            return;
        
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
            // Supposed to be invisible for this item
            foundActive = foundActive || !mesh.isVisible;
            foundInactive = foundInactive || mesh.isVisible;
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
            // Invisible for this item
            mesh.isVisible = ![visible boolValue];
        } else if ([mesh.displayName hasPrefix:[NSString stringWithFormat:@"+%@", self.name]]) {
            // Visible for this item
            mesh.isVisible = [visible boolValue];
        }
    }
    [self didChangeValueForKey:@"visible"];
}

- (BOOL)meshIsRelevant:(GLLItemMesh *)mesh {
    if ([mesh.displayName hasPrefix:[NSString stringWithFormat:@"-%@", self.name]]) {
        return YES;
    }
    if ([mesh.displayName hasPrefix:[NSString stringWithFormat:@"+%@", self.name]]) {
        return YES;
    }
    return NO;
}

@end
