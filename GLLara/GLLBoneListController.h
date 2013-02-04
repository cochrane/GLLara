//
//  GLLBoneListController.h
//  GLLara
//
//  Created by Torsten Kammer on 13.01.13.
//  Copyright (c) 2013 Torsten Kammer. All rights reserved.
//

#import <Cocoa/Cocoa.h>

@class GLLItem;

/*!
 * Source list controller for a list of bones. Child of an item.
 * Also includes the bones of subitems. It creates all bone controllers, not
 * just the root bones. The bone controllers then access it to get their
 * children.
 */
@interface GLLBoneListController : NSObject <NSOutlineViewDataSource>

- (id)initWithItem:(GLLItem *)item outlineView:(NSOutlineView *)outlineView parent:(id)parentController;

@property (nonatomic) GLLItem *item;
@property (nonatomic, readonly) NSMutableArray *boneControllers;
@property (nonatomic, readonly) NSArray *allSelectableControllers;
@property (nonatomic, weak) id parentController;
@property (nonatomic) NSOutlineView *outlineView;

@end
