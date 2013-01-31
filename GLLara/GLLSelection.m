//
//  GLLSelection.m
//  GLLara
//
//  Created by Torsten Kammer on 20.12.12.
//  Copyright (c) 2012 Torsten Kammer. All rights reserved.
//

#import "GLLSelection.h"

#import "GLLItem.h"
#import "LionSubscripting.h"
#import "NSArray+Map.h"

@implementation GLLSelection

+ (NSSet *)keyPathsForValuesAffectingSelectedBones
{
	return [NSSet setWithObject:@"selectedObjects"];
}
+ (NSSet *)keyPathsForValuesAffectingSelectedItems
{
	return [NSSet setWithObject:@"selectedObjects"];
}
+ (NSSet *)keyPathsForValuesAffectingSelectedLights
{
	return [NSSet setWithObject:@"selectedObjects"];
}
+ (NSSet *)keyPathsForValuesAffectingSelectedMeshes
{
	return [NSSet setWithObject:@"selectedObjects"];
}

- (instancetype)init
{
	if (!(self = [super init])) return nil;
	
	self.selectedObjects = [NSMutableArray array];
	
	return self;
}

- (NSArray *)selectedBones;
{
	NSArray *selectedBones = [[self selectedObjects] filteredArrayUsingPredicate:[NSPredicate predicateWithFormat:@"entity.name == \"GLLItemBone\""]];
	NSArray *selectedBonesFromItems = [[self valueForKeyPath:@"selectedItems"] mapAndJoin:^(GLLItem *item) {
		return item.bones.array;
	}];

	return [selectedBones arrayByAddingObjectsFromArray:selectedBonesFromItems];
}

- (NSArray *)selectedItems
{
	return [[self selectedObjects] filteredArrayUsingPredicate:[NSPredicate predicateWithFormat:@"entity.name == \"GLLItem\""]];
}

- (NSArray *)selectedLights
{
	return [[self selectedObjects] filteredArrayUsingPredicate:[NSPredicate predicateWithBlock:^(NSManagedObject *object, NSDictionary *bindings){
		return [object.entity isKindOfEntity:[NSEntityDescription entityForName:@"GLLLight" inManagedObjectContext:object.managedObjectContext]];
	}]];
}

- (NSArray *)selectedMeshes
{
	return [[self selectedObjects] filteredArrayUsingPredicate:[NSPredicate predicateWithFormat:@"entity.name == \"GLLItemMesh\""]];
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
	NSMutableArray *selectedObjects = [self mutableArrayValueForKey:@"selectedObjects"];
	
	// Switch to selecting only bones
	NSArray *selectedBones = [self valueForKey:@"selectedBones"];
	[selectedObjects removeAllObjects];
	[selectedObjects insertObjects:selectedBones atIndexes:[NSIndexSet indexSetWithIndexesInRange:NSMakeRange(0, selectedBones.count)]];
	
	// Insert
	[selectedObjects insertObject:object atIndex:index];
}
- (void)insertObject:(NSManagedObject *)object inSelectedLightsAtIndex:(NSUInteger)index;
{
	NSMutableArray *selectedObjects = [self mutableArrayValueForKey:@"selectedObjects"];
	
	// Switch to selecting only lights
	NSArray *selectedLights = [self valueForKey:@"selectedLights"];
	[selectedObjects removeAllObjects];
	[selectedObjects insertObjects:selectedLights atIndexes:[NSIndexSet indexSetWithIndexesInRange:NSMakeRange(0, selectedLights.count)]];
	
	// Insert
	[selectedObjects insertObject:object atIndex:index];
}
- (void)insertObject:(GLLItemMesh *)object inSelectedMeshesAtIndex:(NSUInteger)index;
{
	NSMutableArray *selectedObjects = [self mutableArrayValueForKey:@"selectedObjects"];
	
	// Switch to selecting only meshes
	NSArray *selectedMeshes = [self valueForKey:@"selectedMeshes"];
	[selectedObjects removeAllObjects];
	[selectedObjects insertObjects:selectedMeshes atIndexes:[NSIndexSet indexSetWithIndexesInRange:NSMakeRange(0, selectedMeshes.count)]];
	
	// Insert
	[selectedObjects insertObject:object atIndex:index];
}
- (void)insertObject:(GLLItem *)object inSelectedItemsAtIndex:(NSUInteger)index
{
	NSMutableArray *selectedObjects = [self mutableArrayValueForKey:@"selectedObjects"];
	
	// Switch to selecting only items
	NSArray *selectedItems = [self valueForKey:@"selectedItems"];
	[selectedObjects removeAllObjects];
	[selectedObjects insertObjects:selectedItems atIndexes:[NSIndexSet indexSetWithIndexesInRange:NSMakeRange(0, selectedItems.count)]];
	
	// Insert
	[selectedObjects insertObject:object atIndex:index];
}

- (void)removeObjectFromSelectedBonesAtIndex:(NSUInteger)index;
{
	NSMutableArray *selectedObjects = [self mutableArrayValueForKey:@"selectedObjects"];
	
	// Switch to selecting only bones
	NSArray *selectedBones = [self valueForKey:@"selectedBones"];
	[selectedObjects removeAllObjects];
	[selectedObjects insertObjects:selectedBones atIndexes:[NSIndexSet indexSetWithIndexesInRange:NSMakeRange(0, selectedBones.count)]];
	
	// Remove
	[selectedObjects removeObjectAtIndex:index];
}
- (void)removeObjectFromSelectedLightsAtIndex:(NSUInteger)index;
{
	NSMutableArray *selectedObjects = [self mutableArrayValueForKey:@"selectedObjects"];
	
	// Switch to selecting only lights
	NSArray *selectedLights = [self valueForKey:@"selectedLights"];
	[selectedObjects removeAllObjects];
	[selectedObjects insertObjects:selectedLights atIndexes:[NSIndexSet indexSetWithIndexesInRange:NSMakeRange(0, selectedLights.count)]];
	
	// Remove
	[selectedObjects removeObjectAtIndex:index];
}
- (void)removeObjectFromSelectedMeshesAtIndex:(NSUInteger)index;
{
	NSMutableArray *selectedObjects = [self mutableArrayValueForKey:@"selectedObjects"];
	
	// Switch to selecting only meshes
	NSArray *selectedMeshes = [self valueForKey:@"selectedMeshes"];
	[selectedObjects removeAllObjects];
	[selectedObjects insertObjects:selectedMeshes atIndexes:[NSIndexSet indexSetWithIndexesInRange:NSMakeRange(0, selectedMeshes.count)]];
	
	// Remove
	[selectedObjects removeObjectAtIndex:index];
}
- (void)removeObjectFromSelectedObjectsAtIndex:(NSUInteger)index;
{
	[self.selectedObjects removeObjectAtIndex:index];
}
- (void)removeObjectFromSelectedItemsAtIndex:(NSUInteger)index
{
	NSMutableArray *selectedObjects = [self mutableArrayValueForKey:@"selectedObjects"];
	
	// Switch to selecting only items
	NSArray *selectedItems = [self valueForKey:@"selectedItems"];
	[selectedObjects removeAllObjects];
	[selectedObjects insertObjects:selectedItems atIndexes:[NSIndexSet indexSetWithIndexesInRange:NSMakeRange(0, selectedItems.count)]];
	
	// Remove
	[selectedObjects removeObjectAtIndex:index];
}

- (void)replaceSelectedObjectsAtIndexes:(NSIndexSet *)indexes withSelectedObjects:(NSArray *)array
{
	[self.selectedObjects replaceObjectsAtIndexes:indexes withObjects:array];
}

- (void)removeSelectedObjectsAtIndexes:(NSIndexSet *)indexes
{
	[self.selectedObjects removeObjectsAtIndexes:indexes];
}

- (void)insertSelectedObjects:(NSArray *)array atIndexes:(NSIndexSet *)indexes
{
	[self.selectedObjects insertObjects:array atIndexes:indexes];
}

- (void)removeSelectedBonesAtIndexes:(NSIndexSet *)indexes
{
	NSMutableArray *selectedObjects = [self mutableArrayValueForKey:@"selectedObjects"];
	
	// Switch to selecting only bones
	NSArray *selectedBones = [self valueForKey:@"selectedBones"];
	[selectedObjects removeAllObjects];
	[selectedObjects insertObjects:selectedBones atIndexes:[NSIndexSet indexSetWithIndexesInRange:NSMakeRange(0, selectedBones.count)]];
	
	// Remove
	[selectedObjects removeObjectsAtIndexes:indexes];
}

@end
