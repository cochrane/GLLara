//
//  TRItemSelectWindowController.m
//  GLLara
//
//  Created by Torsten Kammer on 18.09.12.
//  Copyright (c) 2012 Torsten Kammer. All rights reserved.
//

#import "TRItemSelectWindowController.h"

#import "TR1Level.h"
#import "TR1Moveable.h"
#import "TR1Room.h"
#import "TR1StaticMesh.h"
#import "TRItemView.h"

@interface TRItemSelectWindowController ()

@end

static id staticMeshesMarker = @"Static meshes";
static id roomsMarker = @"Rooms";
static id moveablesMarker = @"Moveables";
static id allRoomsMarker = @"all rooms";

@implementation TRItemSelectWindowController

- (id)init
{
	return [self initWithWindowNibName:@"TRItemSelectWindowController"];
}

- (void)windowDidLoad
{
    [super windowDidLoad];
    
    self.sourceView.dataSource = self;
	self.sourceView.delegate = self;
}

#pragma mark - Outline view data source

- (NSInteger)outlineView:(NSOutlineView *)outlineView numberOfChildrenOfItem:(id)item
{
	if (item == nil)
		return 3;
	
	if (item == staticMeshesMarker)
		return self.level.staticMeshes.count;
	else if (item == roomsMarker)
		return self.level.rooms.count + 1; // Additional for all rooms marker
	else if (item == moveablesMarker)
		return self.level.moveables.count;
	else
		return 0;
}

- (BOOL)outlineView:(NSOutlineView *)outlineView isItemExpandable:(id)item
{
	return [self outlineView:outlineView isGroupItem:item];
}

- (id)outlineView:(NSOutlineView *)outlineView child:(NSInteger)index ofItem:(id)item
{
	if (item == nil)
	{
		switch(index)
		{
			case 0: return moveablesMarker;
			case 1: return staticMeshesMarker;
			case 2: return roomsMarker;
			default: return nil;
		}
	}
	else if (item == staticMeshesMarker)
		return [self.level.staticMeshes objectAtIndex:index];
	else if (item == moveablesMarker)
		return [self.level.moveables objectAtIndex:index];
	else if (item == roomsMarker)
		return (index == 0) ? allRoomsMarker : [self.level.rooms objectAtIndex:index-1];
	else
		return nil;
}

- (id)outlineView:(NSOutlineView *)outlineView objectValueForTableColumn:(NSTableColumn *)tableColumn byItem:(id)item
{
	if (item == moveablesMarker)
		return NSLocalizedStringFromTable(@"Moveables", @"TRItemView", @"source list header");
	if (item == staticMeshesMarker)
		return NSLocalizedStringFromTable(@"Static Objects", @"TRItemView", @"source list header");
	if (item == roomsMarker)
		return NSLocalizedStringFromTable(@"Rooms", @"TRItemView", @"source list header");
	if (item == allRoomsMarker)
		return NSLocalizedStringFromTable(@"Entire level", @"TRItemView", @"source list header");
	if ([item isKindOfClass:[TR1StaticMesh class]])
		return [NSString stringWithFormat:NSLocalizedStringFromTable(@"Static object %lu", @"TRItemView", @"source list entry"), [(TR1StaticMesh *) item objectID]];
	if ([item isKindOfClass:[TR1Room class]])
		return [NSString stringWithFormat:NSLocalizedStringFromTable(@"Room %lu", @"TRItemView", @"source list entry"), [(TR1Room *) item number]];
	if ([item isKindOfClass:[TR1Moveable class]])
		return [NSString stringWithFormat:NSLocalizedStringFromTable(@"Moveable object %lu", @"TRItemView", @"source list entry"), [(TR1Moveable *) item objectID]];
	
	return nil;
}

#pragma mark - Outline view delegate

- (BOOL)outlineView:(NSOutlineView *)outlineView shouldSelectItem:(id)item
{
	return ![self outlineView:outlineView isGroupItem:item];
}
- (BOOL)outlineView:(NSOutlineView *)outlineView isGroupItem:(id)item
{
	return (item == staticMeshesMarker || item == roomsMarker || item == moveablesMarker);
}
- (NSView *)outlineView:(NSOutlineView *)outlineView viewForTableColumn:(NSTableColumn *)tableColumn item:(id)item
{
	NSTableCellView *view = nil;
	if ([self outlineView:outlineView isGroupItem:item])
		view = [outlineView makeViewWithIdentifier:@"HeaderCell" owner:self];
	else
		view = [outlineView makeViewWithIdentifier:@"DataCell" owner:self];
	
	view.textField.stringValue = [self outlineView:outlineView objectValueForTableColumn:tableColumn byItem:item];
	
	return view;
}

- (void)outlineViewSelectionDidChange:(NSNotification *)notification;
{
	NSUInteger selectedRow = self.sourceView.selectedRow;
	if (selectedRow == NSNotFound) return;
	
	id selectedObject = [self.sourceView itemAtRow:selectedRow];
	if ([selectedObject isKindOfClass:[TR1StaticMesh class]])
		[self.itemView showStaticMesh:selectedObject];
	else if ([selectedObject isKindOfClass:[TR1Moveable class]])
		[self.itemView showMoveable:selectedObject];
}

@end
