//
//  GLLOptionalPartController.h
//  GLLara
//
//  Created by Torsten Kammer on 18.04.18.
//  Copyright © 2018 Torsten Kammer. All rights reserved.
//

#import "Cocoa/Cocoa.h"

@class GLLItem;
@class GLLItemOptionalPartMarker;

/*!
 * Item controller for the optional parts of a model (if it has any). This just
 * shows one single source list entry, no children; this entry shows a list of
 * optional model parts in its detail view.
 */
@interface GLLOptionalPartController : NSObject <NSOutlineViewDataSource>

- (id)initWithItem:(GLLItem *)item parent:(id)parentController;

@property (nonatomic, readonly) GLLItem *item;
@property (nonatomic, readonly, weak) id parentController;
@property (nonatomic, readonly) GLLItemOptionalPartMarker *representedObject;

@end
