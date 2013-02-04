//
//  GLLMeshController.h
//  GLLara
//
//  Created by Torsten Kammer on 01.01.13.
//  Copyright (c) 2013 Torsten Kammer. All rights reserved.
//

#import <Cocoa/Cocoa.h>

@class GLLItemMesh;

/*!
 * @abstract Source list controller for a mesh.
 */
@interface GLLMeshController : NSObject

- (id)initWithMesh:(GLLItemMesh *)mesh parentController:(id)parentController;

@property (nonatomic) GLLItemMesh *mesh;
@property (nonatomic, readonly) id representedObject;
@property (nonatomic, weak) id parentController;

@end
