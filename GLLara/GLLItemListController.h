//
//  GLLItemListController.h
//  GLLara
//
//  Created by Torsten Kammer on 17.09.12.
//  Copyright (c) 2012 Torsten Kammer. All rights reserved.
//

#import <Cocoa/Cocoa.h>

/*!
 * Source list controller for a list of items, and direct child of the root.
 */
@interface GLLItemListController : NSObject <NSOutlineViewDataSource>

- (id)initWithManagedObjectContext:(NSManagedObjectContext *)managedObjectContext outlineView:(NSOutlineView *)outlineView;

@property (nonatomic, readonly) NSManagedObjectContext *managedObjectContext;
@property (nonatomic, readonly) NSOutlineView *outlineView;
@property (nonatomic, readonly) NSArray *allSelectableControllers;

@end
