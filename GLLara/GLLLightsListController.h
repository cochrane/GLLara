//
//  GLLLightsListController.h
//  GLLara
//
//  Created by Torsten Kammer on 13.01.13.
//  Copyright (c) 2013 Torsten Kammer. All rights reserved.
//

#import <Cocoa/Cocoa.h>

@interface GLLLightsListController : NSObject <NSOutlineViewDataSource>

- (id)initWithManagedObjectContext:(NSManagedObjectContext *)managedObjectContext outlineView:(NSOutlineView *)outlineView;

@property (nonatomic, readonly) NSManagedObjectContext *managedObjectContext;
@property (nonatomic, readonly) NSOutlineView *outlineView;
@property (nonatomic, readonly) NSArray *allSelectableControllers;

@end
