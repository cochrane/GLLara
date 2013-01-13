//
//  GLLItemListController.m
//  GLLara
//
//  Created by Torsten Kammer on 17.09.12.
//  Copyright (c) 2012 Torsten Kammer. All rights reserved.
//

#import "GLLItemListController.h"

#import "NSArray+Map.h"
#import "GLLItem.h"
#import "GLLItemController.h"

@interface GLLItemListController ()

@property (nonatomic) NSMutableArray *itemControllers;

@end

@implementation GLLItemListController

- (id)initWithManagedObjectContext:(NSManagedObjectContext *)managedObjectContext outlineView:(NSOutlineView *)outlineView;
{
	if (!(self = [super init])) return nil;
	
	_managedObjectContext = managedObjectContext;
	_outlineView = outlineView;
	
	[[NSNotificationCenter defaultCenter] addObserverForName:NSManagedObjectContextObjectsDidChangeNotification object:_managedObjectContext queue:[NSOperationQueue mainQueue] usingBlock:^(NSNotification *notification){
		
		NSArray *removedItemControllers = [self.itemControllers filteredArrayUsingPredicate:[NSPredicate predicateWithFormat:@"item in %@", notification.userInfo[NSDeletedObjectsKey]]];
		[self.itemControllers removeObjectsInArray:removedItemControllers];
		
		NSSet *addedItems = [notification.userInfo[NSInsertedObjectsKey] filteredSetUsingPredicate:[NSPredicate predicateWithFormat:@"entity.name == \"GLLItem\""]];
		NSArray *addedItemControllers = [addedItems map:^(GLLItem *item){
			return [[GLLItemController alloc] initWithItem:item];
		}];
		[self.itemControllers addObjectsFromArray:addedItemControllers];
		[self.itemControllers sortUsingDescriptors:@[ [NSSortDescriptor sortDescriptorWithKey:@"item.displayName" ascending:YES] ]];
		
		[self.outlineView reloadItem:self reloadChildren:YES];
	}];
	
	// Get initial items
	NSFetchRequest *itemRequest = [NSFetchRequest fetchRequestWithEntityName:@"GLLItem"];
	itemRequest.sortDescriptors = @[ [NSSortDescriptor sortDescriptorWithKey:@"displayName" ascending:YES] ];
	
	self.itemControllers = [[_managedObjectContext executeFetchRequest:itemRequest error:NULL] mapMutable:^(GLLItem *item){
		return [[GLLItemController alloc] initWithItem:item];
	}];
	
	return self;
}

#pragma mark - Outline view data source

- (id)outlineView:(NSOutlineView *)outlineView child:(NSInteger)index ofItem:(id)item
{
	return self.itemControllers[index];
}

- (id)outlineView:(NSOutlineView *)outlineView objectValueForTableColumn:(NSTableColumn *)tableColumn byItem:(id)item
{
	return NSLocalizedString(@"Items", @"source view header");
}

- (BOOL)outlineView:(NSOutlineView *)outlineView isItemExpandable:(id)item
{
	return YES;
}

- (NSInteger)outlineView:(NSOutlineView *)outlineView numberOfChildrenOfItem:(id)item
{
	return self.itemControllers.count;
}

#pragma mark - Outline view delegate

- (BOOL)outlineView:(NSOutlineView *)outlineView isGroupItem:(id)item
{
	return YES;
}

@end
