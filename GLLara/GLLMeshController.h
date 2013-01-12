//
//  GLLMeshController.h
//  GLLara
//
//  Created by Torsten Kammer on 01.01.13.
//  Copyright (c) 2013 Torsten Kammer. All rights reserved.
//

#import <Foundation/Foundation.h>

@class GLLItemMesh;

@class GLLMeshController;

@protocol GLLMeshChangeObserver <NSObject>

- (void)meshDidChange:(GLLMeshController *)controller;

@end

@interface GLLMeshController : NSObject

@property (nonatomic) GLLItemMesh *mesh;

- (void)addMeshChangeObserver:(id <GLLMeshChangeObserver>)observer;
- (void)removeMeshChangeObserver:(id <GLLMeshChangeObserver>)observer;

@end
