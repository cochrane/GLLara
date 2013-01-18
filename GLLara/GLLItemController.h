//
//  GLLItemController.h
//  GLLara
//
//  Created by Torsten Kammer on 17.09.12.
//  Copyright (c) 2012 Torsten Kammer. All rights reserved.
//

#import <Cocoa/Cocoa.h>

@class GLLItem;

/*!
 * The item controller provides the data for an item's user interface. In particular, it implements GLLSourceListItem, using source list markers to provide the grouping.
 */
@interface GLLItemController : NSObject <NSOutlineViewDataSource>

- (id)initWithItem:(GLLItem *)item parent:(id)parentController;

@property (nonatomic) GLLItem *item;
@property (nonatomic, readonly) id representedObject;
@property (nonatomic, readonly) NSArray *allSelectableControllers;
@property (nonatomic, weak) id parentController;

@end
