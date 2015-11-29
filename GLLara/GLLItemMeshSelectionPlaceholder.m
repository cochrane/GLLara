//
//  GLLItemMeshSelectionPlaceholder.m
//  GLLara
//
//  Created by Torsten Kammer on 29.11.15.
//  Copyright (c) 2015 Torsten Kammer. All rights reserved.
//

#import "GLLItemMeshSelectionPlaceholder.h"

#import "GLLItemMesh.h"

@interface GLLItemMeshSelectionPlaceholder ()

@property (nonatomic, copy) NSString *keyPath;

@end

@implementation GLLItemMeshSelectionPlaceholder

- (instancetype)initWithKeyPath:(NSString *)keyPath selection:(GLLSelection *)selection;
{
    NSParameterAssert(keyPath);
    
    if (!(self = [super initWithSelection:selection typeKey:@"selectedMeshes"]))
        return nil;
    
    _keyPath = keyPath;
    
    [self update];
    
    return self;
}

- (id)valueFrom:(GLLItemMesh *)sourceObject {
    return [sourceObject valueForKeyPath:self.keyPath];
}

- (void)setValue:(id)value onSourceObject:(GLLItemMesh *)object {
    [object setValue:value forKeyPath:self.keyPath];
}

@end
