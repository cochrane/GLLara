//
//  GLLSourceListController.m
//  GLLara
//
//  Created by Torsten Kammer on 26.09.12.
//  Copyright (c) 2012 Torsten Kammer. All rights reserved.
//

#import "GLLSourceListController.h"

#import "GLLItemListController.h"
#import "GLLSourceListMarker.h"

@interface GLLSourceListController ()
{
	GLLItemListController *itemListController;
	NSArrayController *lightsController;
	GLLSourceListMarker *lightsMarker;
	GLLSourceListMarker *settingsMarker;
}

@end

@implementation GLLSourceListController

- (id)initWithManagedObjectContext:(NSManagedObjectContext *)managedObjectContext;
{
    if (!(self = [super init])) return nil;
    
	_managedObjectContext = managedObjectContext;
	
	lightsController = [[NSArrayController alloc] initWithContent:nil];
	lightsController.managedObjectContext = self.managedObjectContext;
	lightsController.entityName = @"GLLLight";
	lightsController.automaticallyPreparesContent = YES;
	lightsController.automaticallyRearrangesObjects = YES;
	lightsController.sortDescriptors = @[ [NSSortDescriptor sortDescriptorWithKey:@"index" ascending:YES] ];
	[lightsController fetch:self];
	
	lightsMarker = [[GLLSourceListMarker alloc] initWithObject:lightsController childrenKeyPath:@"arrangedObjects"];
	lightsMarker.isSourceListHeader = YES;
	lightsMarker.sourceListDisplayName = NSLocalizedString(@"Lights", @"source list header: lights");
	
	settingsMarker = [[GLLSourceListMarker alloc] initWithObject:nil childrenKeyPath:nil];
	settingsMarker.isSourceListHeader = YES;
	settingsMarker.sourceListDisplayName = NSLocalizedString(@"Settings", @"source list header: lights");
	
	itemListController = [[GLLItemListController alloc] initWithManagedObjectContext:managedObjectContext];
	
	_treeController = [[NSTreeController alloc] init];
	_treeController.childrenKeyPath = @"sourceListChildren";
	_treeController.leafKeyPath = @"isLeafInSourceList";
	[_treeController bind:@"content" toObject:self withKeyPath:@"sourceListRoots" options:nil];
	
    return self;
}


#pragma mark - Filling the tree controller

- (NSUInteger)countOfSourceListRoots;
{
	return 3;
}

- (id)objectInSourceListRootsAtIndex:(NSUInteger)index;
{
	switch(index)
	{
		case 0: return lightsMarker;
		case 1: return itemListController;
		case 2: return settingsMarker;
		default: return nil;
	}
}


@end
