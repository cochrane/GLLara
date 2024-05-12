//
//  GLLRenderParameterSelectionPlaceholder.m
//  GLLara
//
//  Created by Torsten Kammer on 29.11.15.
//  Copyright (c) 2015 Torsten Kammer. All rights reserved.
//

#import "GLLRenderParameterSelectionPlaceholder.h"

#import "GLLItemMesh.h"
#import "GLLara-Swift.h"

@interface GLLRenderParameterSelectionPlaceholder ()

@property (nonatomic, copy) NSString *parameterName;
@property (nonatomic, copy) NSString *keyPath;

@end

@implementation GLLRenderParameterSelectionPlaceholder

- (instancetype)initWithParameterName:(NSString *)parameterName keyPath:(NSString *)keyPath selection:(GLLSelection *)selection;
{
    NSParameterAssert(parameterName);
    NSParameterAssert(keyPath);
    
    if (!(self = [super initWithSelection:selection typeKey:@"selectedMeshes"]))
        return nil;
    
    _parameterName = parameterName;
    _keyPath = keyPath;
    
    [self update];
    
    return self;
}

- (id)valueFrom:(GLLItemMesh *)sourceObject {
    GLLRenderParameter *parameter = [sourceObject renderParameterWithName:self.parameterName];
    return [parameter valueForKeyPath:self.keyPath];
}

- (void)setValue:(id)value onSourceObject:(GLLItemMesh *)object {
    GLLRenderParameter *parameter = [object renderParameterWithName:self.parameterName];
    [parameter setValue:value forKeyPath:self.keyPath];
}

@end
