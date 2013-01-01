//
//  GLLSelection.m
//  GLLara
//
//  Created by Torsten Kammer on 20.12.12.
//  Copyright (c) 2012 Torsten Kammer. All rights reserved.
//

#import "GLLSelection.h"

#import "GLLItemController.h"

@implementation GLLSelection

@synthesize selectedBones=_selectedBones;

+ (NSSet *)keyPathsForValuesAffectingSelectedObjects
{
	return [NSSet setWithObjects:@"selectedBones", @"selectedMeshes", @"selectedLights", @"selectedItems", nil];
}

+ (NSSet *)keyPathsForValuesAffectingSelectedBones
{
	return [NSSet setWithObject:@"selectedItems"];
}

- (instancetype)init
{
	if (!(self = [super init])) return nil;
	
	self.selectedBones = [NSMutableArray array];
	self.selectedItems = [NSMutableArray array];
	self.selectedMeshes = [NSMutableArray array];
	self.selectedLights = [NSMutableArray array];
	
	return self;
}

- (void)setSelectedObjects:(NSMutableArray *)selectedObjects
{
	// Check that all objects have the same entity
	NSEntityDescription *lightEntity = [NSEntityDescription entityForName:@"GLLLight" inManagedObjectContext:self.managedObjectContext];
	NSEntityDescription *boneEntity = [NSEntityDescription entityForName:@"GLLItemBone" inManagedObjectContext:self.managedObjectContext];
	NSEntityDescription *meshEntity = [NSEntityDescription entityForName:@"GLLItemMesh" inManagedObjectContext:self.managedObjectContext];
	NSEntityDescription *itemEntity = [NSEntityDescription entityForName:@"GLLItem" inManagedObjectContext:self.managedObjectContext];
	
	BOOL allLights = NO;
	BOOL allBones = NO;
	BOOL allMeshes = NO;
	BOOL allItems = NO;
	BOOL itemsAreControllers = NO;
	
	for (NSManagedObject *object in selectedObjects)
	{
		if (![object respondsToSelector:@selector(entity)])
		{
			if ([object isKindOfClass:[GLLItemController class]])
			{
				allItems = YES;
				NSAssert(allMeshes == NO && allBones == NO && allLights == NO, @"Selection includes several types");
				itemsAreControllers = YES;
			}
			else
				return; // Object that should not be part of the selection.
		}
		else if ([object.entity isKindOfEntity:boneEntity])
		{
			allBones = YES;
			NSAssert(allLights == NO && allMeshes == NO && allItems == NO, @"Selection includes several types");
		}
		else if ([object.entity isKindOfEntity:meshEntity])
		{
			allMeshes = YES;
			NSAssert(allLights == NO && allBones == NO && allItems == NO, @"Selection includes several types");
		}
		else if ([object.entity isKindOfEntity:lightEntity])
		{
			allLights = YES;
			NSAssert(allMeshes == NO && allBones == NO && allItems == NO, @"Selection includes several types");
		}
		else if ([object.entity isKindOfEntity:itemEntity])
		{
			allItems = YES;
			NSAssert(allMeshes == NO && allBones == NO && allLights == NO, @"Selection includes several types");
		}
		else
			NSAssert(false, @"Entity %@ not allowed in selection", object.entity);
	}
	
	[self clearSelection];
	
	if (allLights)
		self.selectedLights = selectedObjects;
	else if (allBones)
		self.selectedBones = selectedObjects;
	else if (allMeshes)
		self.selectedMeshes = selectedObjects;
	else if (allItems)
	{
		if (itemsAreControllers)
		{
			self.selectedItems = [NSMutableArray arrayWithArray:[selectedObjects valueForKeyPath:@"item"]];
		}
		else
		{
			self.selectedItems = selectedObjects;
		}
	}
}
- (NSMutableArray *)selectedObjects
{
	if (self.selectedItems.count > 0)
		return self.selectedItems;
	if (self.selectedBones.count > 0)
		return self.selectedBones;
	else if (self.selectedMeshes.count > 0)
		return self.selectedMeshes;
	else
		return self.selectedLights;
}

- (NSArray *)selectedBones;
{
	if (_selectedBones.count == 0 && self.selectedItems.count > 0)
		return [self.selectedItems valueForKeyPath:@"@unionOfSets.bones"];
	
	return _selectedBones;
}

- (void)setSelectedBones:(NSMutableArray *)selectedBones
{
	[self clearSelection];
	_selectedBones = selectedBones;
}

- (void)setSelectedMeshes:(NSMutableArray *)selectedMeshes
{
	[self clearSelection];
	_selectedMeshes = selectedMeshes;
}

- (void)setSelectedLights:(NSMutableArray *)selectedLights
{
	[self clearSelection];
	_selectedLights = selectedLights;
}
- (void)setSelectedItems:(NSMutableArray *)selectedItems
{
	[self clearSelection];
	_selectedItems = selectedItems;
}

- (NSUInteger)countOfSelectedBones;
{
	return self.selectedBones.count;
}
- (NSUInteger)countOfSelectedLights;
{
	return self.selectedLights.count;
}
- (NSUInteger)countOfSelectedMeshes;
{
	return self.selectedMeshes.count;
}
- (NSUInteger)countOfSelectedObjects;
{
	return self.selectedObjects.count;
}
- (NSUInteger)countOfSelectedItems
{
	return self.selectedItems.count;
}

- (NSManagedObject *)objectInSelectedLightsAtIndex:(NSUInteger)index;
{
	return self.selectedLights[index];
}
- (GLLItemBone *)objectInSelectedBonesAtIndex:(NSUInteger)index;
{
	return self.selectedBones[index];
}
- (GLLItemMesh *)objectInSelectedMeshesAtIndex:(NSUInteger)index;
{
	return self.selectedMeshes[index];
}
- (NSManagedObject *)objectInSelectedObjectsAtIndex:(NSUInteger)index;
{
	return self.selectedObjects[index];
}
- (GLLItem *)objectInSelectedItemsAtIndex:(NSUInteger)index;
{
	return self.selectedItems[index];
}

- (void)insertObject:(GLLItemBone *)object inSelectedBonesAtIndex:(NSUInteger)index;
{
	// Reject if selection is not bones
	if (self.countOfSelectedLights > 0 || self.countOfSelectedMeshes > 0)
		return;
	
	// If selection is items, copy bones of item to the array
	if (self.countOfSelectedItems > 0)
	{
		_selectedBones = self.selectedBones;
		[[self mutableArrayValueForKey:@"selectedItems"] removeAllObjects];
	}
	
	[self.selectedBones insertObject:object atIndex:index];
}
- (void)insertObject:(NSManagedObject *)object inSelectedLightsAtIndex:(NSUInteger)index;
{
	// Reject if selection is not lights
	if (self.countOfSelectedBones > 0 || self.countOfSelectedMeshes > 0 || self.countOfSelectedItems > 0)
		return;
	
	[self.selectedLights insertObject:object atIndex:index];
}
- (void)insertObject:(GLLItemMesh *)object inSelectedMeshesAtIndex:(NSUInteger)index;
{
	// Reject if selection is not meshes
	if (self.countOfSelectedBones > 0 || self.countOfSelectedLights > 0 || self.countOfSelectedItems > 0)
		return;
	
	[self.selectedMeshes insertObject:object atIndex:index];
}
- (void)insertObject:(NSManagedObject *)object inSelectedObjectsAtIndex:(NSUInteger)index;
{	
	if ([object.entity isKindOfEntity:[NSEntityDescription entityForName:@"GLLItemBone" inManagedObjectContext:self.managedObjectContext]])
		[self insertObject:(GLLItemBone *)object inSelectedBonesAtIndex:index];
	else if ([object.entity isKindOfEntity:[NSEntityDescription entityForName:@"GLLItemMesh" inManagedObjectContext:self.managedObjectContext]])
		[self insertObject:(GLLItemMesh *)object inSelectedMeshesAtIndex:index];
	else if ([object.entity isKindOfEntity:[NSEntityDescription entityForName:@"GLLLight" inManagedObjectContext:self.managedObjectContext]])
		[self insertObject:object inSelectedLightsAtIndex:index];
	else if ([object.entity isKindOfEntity:[NSEntityDescription entityForName:@"GLLItem" inManagedObjectContext:self.managedObjectContext]])
		[self insertObject:(GLLItem *) object inSelectedItemsAtIndex:index];
}
- (void)insertObject:(GLLItem *)object inSelectedItemsAtIndex:(NSUInteger)index
{
	[self.selectedItems insertObject:object atIndex:index];
}

- (void)removeObjectFromSelectedBonesAtIndex:(NSUInteger)index;
{
	// If selection is items, copy bones of item to the array
	if (self.countOfSelectedItems > 0)
	{
		_selectedBones = self.selectedBones;
		[[self mutableArrayValueForKey:@"selectedItems"] removeAllObjects];
	}

	[self.selectedBones removeObjectAtIndex:index];
}
- (void)removeObjectFromSelectedLightsAtIndex:(NSUInteger)index;
{
	[self.selectedLights removeObjectAtIndex:index];
}
- (void)removeObjectFromSelectedMeshesAtIndex:(NSUInteger)index;
{
	[self.selectedMeshes removeObjectAtIndex:index];
}
- (void)removeObjectFromSelectedObjectsAtIndex:(NSUInteger)index;
{
	[self.selectedObjects removeObjectAtIndex:index];
}
- (void)removeObjectFromSelectedItemsAtIndex:(NSUInteger)index
{
	[self.selectedItems removeObjectAtIndex:index];
}

- (void)clearSelection

{
	[self willChangeValueForKey:@"selectedBones"];
	[self willChangeValueForKey:@"selectedLights"];
	[self willChangeValueForKey:@"selectedMeshes"];
	[self willChangeValueForKey:@"selectedItems"];
	
	_selectedBones = [NSMutableArray array];
	_selectedMeshes = [NSMutableArray array];
	_selectedLights = [NSMutableArray array];
	_selectedItems = [NSMutableArray array];
	
	[self didChangeValueForKey:@"selectedBones"];
	[self didChangeValueForKey:@"selectedLights"];
	[self didChangeValueForKey:@"selectedMeshes"];
	[self didChangeValueForKey:@"selectedItems"];
}

@end
