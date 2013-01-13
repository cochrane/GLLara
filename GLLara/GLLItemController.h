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

- (id)initWithItem:(GLLItem *)item;

@property (nonatomic) GLLItem *item;

@end
