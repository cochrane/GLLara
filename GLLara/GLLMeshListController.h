//
//  GLLMeshListController.h
//  GLLara
//
//  Created by Torsten Kammer on 13.01.13.
//  Copyright (c) 2013 Torsten Kammer. All rights reserved.
//

#import <Cocoa/Cocoa.h>

@class GLLItem;

/*!
 * Source list controller for a list of meshes. Child of an item.
 */
@interface GLLMeshListController : NSObject <NSOutlineViewDataSource>

- (id)initWithItem:(GLLItem *)item parent:(id)parentController;

@property (nonatomic) GLLItem *item;
@property (nonatomic, readonly) NSArray *allSelectableControllers;
@property (nonatomic, weak) id parentController;

@end
