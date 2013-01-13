//
//  GLLSourceListController.m
//  GLLara
//
//  Created by Torsten Kammer on 26.09.12.
//  Copyright (c) 2012 Torsten Kammer. All rights reserved.
//

#import "GLLSourceListController.h"

#import "GLLLightsListController.h"
#import "GLLItemListController.h"
#import "GLLSettingsListController.h"

@interface GLLSourceListController ()
{
	GLLLightsListController *lightsListController;
	GLLItemListController *itemListController;
	GLLSettingsListController *settingsListController;
}

@end

@implementation GLLSourceListController

- (id)initWithManagedObjectContext:(NSManagedObjectContext *)managedObjectContext outlineView:(NSOutlineView *)outlineView;
{
    if (!(self = [super init])) return nil;
    
	_managedObjectContext = managedObjectContext;
	
	lightsListController = [[GLLLightsListController alloc] initWithManagedObjectContext:_managedObjectContext outlineView:outlineView];
	itemListController = [[GLLItemListController alloc] initWithManagedObjectContext:_managedObjectContext outlineView:outlineView];
	settingsListController = [[GLLSettingsListController alloc] initWithManagedObjectContext:_managedObjectContext outlineView:outlineView];
	
	return self;
}

#pragma mark - Outline view data source

- (id)outlineView:(NSOutlineView *)outlineView child:(NSInteger)index ofItem:(id)item
{
	if (item) return [item outlineView:outlineView child:index ofItem:item];

	switch (index)
	{
		case 0: return lightsListController;
		case 1: return itemListController;
		case 2: return settingsListController;
		default: return nil;
	}
}

- (id)outlineView:(NSOutlineView *)outlineView objectValueForTableColumn:(NSTableColumn *)tableColumn byItem:(id)item
{
	if (item) return [item outlineView:outlineView objectValueForTableColumn:tableColumn byItem:item];
	
	return nil;
}

- (BOOL)outlineView:(NSOutlineView *)outlineView isItemExpandable:(id)item
{
	if (item == nil) return YES;
	else return [item outlineView:outlineView isItemExpandable:item];
}

- (NSInteger)outlineView:(NSOutlineView *)outlineView numberOfChildrenOfItem:(id)item
{
	if (item == nil) return 3;
	else return [item outlineView:outlineView numberOfChildrenOfItem:item];
}

@end
