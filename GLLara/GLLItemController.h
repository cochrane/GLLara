//
//  GLLItemController.h
//  GLLara
//
//  Created by Torsten Kammer on 17.09.12.
//  Copyright (c) 2012 Torsten Kammer. All rights reserved.
//

#import <Cocoa/Cocoa.h>

@class GLLMeshListController;
@class GLLBoneListController;
@class GLLOptionalPartController;

@class GLLItem;

/*!
 * Source list controller for an item.
 */
@interface GLLItemController : NSObject <NSOutlineViewDataSource>

- (id)initWithItem:(GLLItem *)item outlineView:(NSOutlineView *)outlineView parent:(id)parentController;

@property (nonatomic) GLLItem *item;
@property (nonatomic, readonly) id representedObject;
@property (nonatomic, readonly) NSArray *allSelectableControllers;
@property (nonatomic, weak) id parentController;
@property (nonatomic, readonly) NSOutlineView *outlineView;


@property (nonatomic) GLLMeshListController *meshListController;
@property (nonatomic) GLLBoneListController *boneListController;
@property (nonatomic) GLLOptionalPartController *optionalPartsController; // can be null
@property (nonatomic) NSMutableArray *childrenControllers;

@end
