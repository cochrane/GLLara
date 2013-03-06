//
//  GLLSelection.m
//  GLLara
//
//  Created by Torsten Kammer on 20.12.12.
//  Copyright (c) 2012 Torsten Kammer. All rights reserved.
//

#import "GLLSelection.h"

#import "GLLItem.h"
#import "GLLItemBone.h"
#import "GLLItemMesh.h"
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

- (instancetype)initWithManagedObjectContext:(NSManagedObjectContext *)context;
{
	if (!(self = [super init])) return nil;
	
	self.selectedObjects = [NSMutableArray array];
	self.managedObjectContext = context;
	
	__weak id weakSelf = self;
	[[NSNotificationCenter defaultCenter] addObserverForName:NSManagedObjectContextObjectsDidChangeNotification object:self.managedObjectContext queue:[NSOperationQueue mainQueue] usingBlock:^(NSNotification *notification){
		__strong GLLSelection *self = weakSelf;
		
		[[self mutableArrayValueForKeyPath:@"selectedObjects"]  removeObjectsInArray:[notification.userInfo[NSDeletedObjectsKey] allObjects]];
	}];
	
	return self;
}

- (NSArray *)selectedBones;
{
	if ([self.selectedObjects.lastObject isKindOfClass:[GLLItemBone class]])
		return self.selectedObjects;
	else if ([self.selectedObjects.lastObject isKindOfClass:[GLLItem class]])
		return [self.selectedItems mapAndJoin:^(GLLItem *item){
			return item.bones.array;
		}];
	else
		return @[];
}

- (NSArray *)selectedItems
{
	if ([self.selectedObjects.lastObject isKindOfClass:[GLLItem class]])
		return self.selectedObjects;
	else if ([self.selectedObjects.lastObject isKindOfClass:[GLLItemBone class]])
		return [self.selectedObjects valueForKeyPath:@"@distinctUnionOfObjects.item"];
	else if ([self.selectedObjects.lastObject isKindOfClass:[GLLItemBone class]])
		return [self.selectedObjects valueForKeyPath:@"@distinctUnionOfObjects.items"];
	else
		return @[];
}

- (NSArray *)selectedLights
{
	return [[self selectedObjects] filteredArrayUsingPredicate:[NSPredicate predicateWithBlock:^(NSManagedObject *object, NSDictionary *bindings){
		return [object.entity isKindOfEntity:[NSEntityDescription entityForName:@"GLLLight" inManagedObjectContext:object.managedObjectContext]];
	}]];
}

- (NSArray *)selectedMeshes
{
	if ([self.selectedObjects.lastObject isKindOfClass:[GLLItemMesh class]])
		return self.selectedObjects;
	else
		return @[];
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
	NSArray *selectedBones = [[self valueForKey:@"selectedBones"] copy];
	[selectedObjects removeAllObjects];
	[selectedObjects insertObjects:selectedBones atIndexes:[NSIndexSet indexSetWithIndexesInRange:NSMakeRange(0, selectedBones.count)]];
	
	// Insert
	[selectedObjects insertObject:object atIndex:index];
}
- (void)insertObject:(NSManagedObject *)object inSelectedLightsAtIndex:(NSUInteger)index;
{
	NSMutableArray *selectedObjects = [self mutableArrayValueForKey:@"selectedObjects"];
	
	// Switch to selecting only lights
	NSArray *selectedLights = [[self valueForKey:@"selectedLights"] copy];
	[selectedObjects removeAllObjects];
	[selectedObjects insertObjects:selectedLights atIndexes:[NSIndexSet indexSetWithIndexesInRange:NSMakeRange(0, selectedLights.count)]];
	
	// Insert
	[selectedObjects insertObject:object atIndex:index];
}
- (void)insertObject:(GLLItemMesh *)object inSelectedMeshesAtIndex:(NSUInteger)index;
{
	NSMutableArray *selectedObjects = [self mutableArrayValueForKey:@"selectedObjects"];
	
	// Switch to selecting only meshes
	NSArray *selectedMeshes = [[self valueForKey:@"selectedMeshes"] copy];
	[selectedObjects removeAllObjects];
	[selectedObjects insertObjects:selectedMeshes atIndexes:[NSIndexSet indexSetWithIndexesInRange:NSMakeRange(0, selectedMeshes.count)]];
	
	// Insert
	[selectedObjects insertObject:object atIndex:index];
}
- (void)insertObject:(GLLItem *)object inSelectedItemsAtIndex:(NSUInteger)index
{
	NSMutableArray *selectedObjects = [self mutableArrayValueForKey:@"selectedObjects"];
	
	// Switch to selecting only items
	NSArray *selectedItems = [[self valueForKey:@"selectedItems"] copy];
	[selectedObjects removeAllObjects];
	[selectedObjects insertObjects:selectedItems atIndexes:[NSIndexSet indexSetWithIndexesInRange:NSMakeRange(0, selectedItems.count)]];
	
	// Insert
	[selectedObjects insertObject:object atIndex:index];
}

- (void)removeObjectFromSelectedBonesAtIndex:(NSUInteger)index;
{
	NSMutableArray *selectedObjects = [self mutableArrayValueForKey:@"selectedObjects"];
	
	// Switch to selecting only bones
	NSArray *selectedBones = [[self valueForKey:@"selectedBones"] copy];
	[selectedObjects removeAllObjects];
	[selectedObjects insertObjects:selectedBones atIndexes:[NSIndexSet indexSetWithIndexesInRange:NSMakeRange(0, selectedBones.count)]];
	
	// Remove
	[selectedObjects removeObjectAtIndex:index];
}
- (void)removeObjectFromSelectedLightsAtIndex:(NSUInteger)index;
{
	NSMutableArray *selectedObjects = [self mutableArrayValueForKey:@"selectedObjects"];
	
	// Switch to selecting only lights
	NSArray *selectedLights = [[self valueForKey:@"selectedLights"] copy];
	[selectedObjects removeAllObjects];
	[selectedObjects insertObjects:selectedLights atIndexes:[NSIndexSet indexSetWithIndexesInRange:NSMakeRange(0, selectedLights.count)]];
	
	// Remove
	[selectedObjects removeObjectAtIndex:index];
}
- (void)removeObjectFromSelectedMeshesAtIndex:(NSUInteger)index;
{
	NSMutableArray *selectedObjects = [self mutableArrayValueForKey:@"selectedObjects"];
	
	// Switch to selecting only meshes
	NSArray *selectedMeshes = [[self valueForKey:@"selectedMeshes"] copy];
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
	NSArray *selectedItems = [[self valueForKey:@"selectedItems"] copy];
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
	NSArray *selectedBones = [[self valueForKey:@"selectedBones"] copy];
	[selectedObjects removeAllObjects];
	[selectedObjects insertObjects:selectedBones atIndexes:[NSIndexSet indexSetWithIndexesInRange:NSMakeRange(0, selectedBones.count)]];
	
	// Remove
	[selectedObjects removeObjectsAtIndexes:indexes];
}

@end
