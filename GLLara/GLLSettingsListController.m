//
//  GLLSettingsListController.m
//  GLLara
//
//  Created by Torsten Kammer on 13.01.13.
//  Copyright (c) 2013 Torsten Kammer. All rights reserved.
//

#import "GLLSettingsListController.h"

@implementation GLLSettingsListController

- (id)initWithManagedObjectContext:(NSManagedObjectContext *)managedObjectContext outlineView:(NSOutlineView *)outlineView;
{
    if (!(self = [super init])) return nil;
    
	_managedObjectContext = managedObjectContext;
	
	return self;
}

#pragma mark - Outline view data source

- (id)outlineView:(NSOutlineView *)outlineView child:(NSInteger)index ofItem:(id)item
{
	return nil;
}

- (id)outlineView:(NSOutlineView *)outlineView objectValueForTableColumn:(NSTableColumn *)tableColumn byItem:(id)item
{
	if (item == self) return NSLocalizedString(@"Settings", @"source view header");
	
	return nil;
}

- (BOOL)outlineView:(NSOutlineView *)outlineView isItemExpandable:(id)item
{
	if (item == self) return YES;
	else return NO;
}

- (NSInteger)outlineView:(NSOutlineView *)outlineView numberOfChildrenOfItem:(id)item
{
	return 0;
}

@end
