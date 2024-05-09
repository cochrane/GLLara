//
//  GLLItemController.m
//  GLLara
//
//  Created by Torsten Kammer on 17.09.12.
//  Copyright (c) 2012 Torsten Kammer. All rights reserved.
//

#import "GLLItemController.h"

#import "GLLItem.h"
#import "GLLBoneListController.h"
#import "GLLMeshListController.h"
#import "GLLSubItemController.h"
#import "NSArray+Map.h"
#import "GLLara-Swift.h"

@interface GLLItemController ()
// How many controllers for specific topics (as opposed to child items) there
// are. Two normally, three if the item has optional parts.
@property (nonatomic, readonly) NSUInteger fixedControllerCount;
@end

@implementation GLLItemController

- (id)initWithItem:(GLLItem *)item outlineView:(NSOutlineView *)outlineView parent:(id)parentController;
{
	if (!(self = [super init])) return nil;
	
	_outlineView = outlineView;
	
	self.item = item;
	self.parentController = parentController;
	self.meshListController = [[GLLMeshListController alloc] initWithItem:item parent:self];
	self.boneListController = [[GLLBoneListController alloc] initWithItem:item outlineView:outlineView parent:self];
    
    if (self.item.hasOptionalParts) {
        self.optionalPartsController = [[GLLOptionalPartController alloc] initWithItem:item parent:self];
    }
	
	[[NSNotificationCenter defaultCenter] addObserverForName:NSManagedObjectContextObjectsDidChangeNotification object:self.item.managedObjectContext queue:[NSOperationQueue mainQueue] usingBlock:^(NSNotification *notification){
		
		NSArray *removedItemControllers = [self.childrenControllers filteredArrayUsingPredicate:[NSPredicate predicateWithFormat:@"item in %@", notification.userInfo[NSDeletedObjectsKey]]];
		[self.childrenControllers removeObjectsInArray:removedItemControllers];
		
		NSSet *addedItems = [notification.userInfo[NSInsertedObjectsKey] filteredSetUsingPredicate:[NSPredicate predicateWithFormat:@"entity.name == \"GLLItem\""]];
		NSArray *addedItemControllers = [addedItems map:^(GLLItem *item){
			if ([notification.userInfo[NSDeletedObjectsKey] containsObject:item]) return (id) nil; // Objects that were deleted again before this was called.
			if (item.parent != self.item) return (id) nil;
			return (id) [[GLLSubItemController alloc] initWithItem:item outlineView:self.outlineView parent:self];
		}];
		[self.childrenControllers addObjectsFromArray:addedItemControllers];
		[self.childrenControllers sortUsingDescriptors:@[ [NSSortDescriptor sortDescriptorWithKey:@"item.displayName" ascending:YES] ]];
		
		[self.outlineView reloadItem:self reloadChildren:YES];
	}];
	
	// Get initial child items
	NSFetchRequest *itemRequest = [NSFetchRequest fetchRequestWithEntityName:@"GLLItem"];
	itemRequest.sortDescriptors = @[ [NSSortDescriptor sortDescriptorWithKey:@"displayName" ascending:YES] ];
	itemRequest.predicate = [NSPredicate predicateWithFormat:@"parent == %@", self.item];
	
	self.childrenControllers = [[self.item.managedObjectContext executeFetchRequest:itemRequest error:NULL] mapMutable:^(GLLItem *item){
		return [[GLLSubItemController alloc] initWithItem:item outlineView:self.outlineView parent:self];
	}];
		
	return self;
}

- (id)representedObject
{
	return self.item;
}

- (NSArray *)allSelectableControllers
{
	NSMutableArray *result = [NSMutableArray arrayWithObject:self];
	[result addObjectsFromArray:self.meshListController.allSelectableControllers];
	[result addObjectsFromArray:self.boneListController.allSelectableControllers];
    if (self.optionalPartsController) {
        [result addObject:self.optionalPartsController];
    }
	return result;
}

- (NSUInteger)fixedControllerCount {
    return self.optionalPartsController ? 3 : 2;
}

#pragma mark - Outline View Data Source

- (id)outlineView:(NSOutlineView *)outlineView child:(NSInteger)index ofItem:(id)item
{
	switch (index)
	{
		case 0: return self.meshListController;
		case 1: return self.boneListController;
        case 2:
            if (self.optionalPartsController) {
                return self.optionalPartsController;
            } else {
                return self.childrenControllers[index - self.fixedControllerCount];
            }
		default: return self.childrenControllers[index - self.fixedControllerCount];
	}
}

- (id)outlineView:(NSOutlineView *)outlineView objectValueForTableColumn:(NSTableColumn *)tableColumn byItem:(id)item
{
	return self.item.displayName;
}

- (void)outlineView:(NSOutlineView *)outlineView setObjectValue:(id)object forTableColumn:(NSTableColumn *)tableColumn byItem:(id)item
{
	self.item.displayName = object;
}

- (BOOL)outlineView:(NSOutlineView *)outlineView isItemExpandable:(id)item
{
	return YES;
}

- (NSInteger)outlineView:(NSOutlineView *)outlineView numberOfChildrenOfItem:(id)item
{
	return self.fixedControllerCount + self.childrenControllers.count;
}

#pragma mark - Outline View Delegate

- (BOOL)outlineView:(NSOutlineView *)outlineView shouldEditTableColumn:(NSTableColumn *)tableColumn item:(id)item
{
	return YES;
}

@end
