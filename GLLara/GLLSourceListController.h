//
//  GLLSourceListController.h
//  GLLara
//
//  Created by Torsten Kammer on 26.09.12.
//  Copyright (c) 2012 Torsten Kammer. All rights reserved.
//

#import <Cocoa/Cocoa.h>

@interface GLLSourceListController : NSObject

- (id)initWithManagedObjectContext:(NSManagedObjectContext *)managedObjectContext;

@property (nonatomic, retain, readonly) NSManagedObjectContext *managedObjectContext;

@property (nonatomic, retain) NSTreeController *treeController;

- (NSUInteger)countOfSourceListRoots;
- (id)objectInSourceListRootsAtIndex:(NSUInteger)index;

@end
