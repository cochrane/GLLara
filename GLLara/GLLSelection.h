//
//  GLLSelection.h
//  GLLara
//
//  Created by Torsten Kammer on 20.12.12.
//  Copyright (c) 2012 Torsten Kammer. All rights reserved.
//

#import <Foundation/Foundation.h>
#import <CoreData/CoreData.h>

@class GLLItem;
@class GLLItemBone;
@class GLLItemMesh;

/*!
 * @abstract Stores a document's selection.
 * @discussion A selection can be of bones, items, lights, or meshes. However,
 * this can also be expanded; for example, if a mesh is selected, then the
 * selected bones are not empty, but contain all of a mesh. All these details
 * are handled by this class.
 *
 * The various arrays should be accessed by (mutable)valueForKey(Path) only. The
 * actually implemented array accessors are subject to change, and not all of
 * them are in this header. The key paths are:
 * - selectedObjects
 * - selectedItems
 * - selectedBones
 * - selectedLights
 * - selectedMeshes
 */
@interface GLLSelection : NSObject

- (instancetype)initWithManagedObjectContext:(NSManagedObjectContext *)context;

@property (nonatomic) NSManagedObjectContext *managedObjectContext;

@property (nonatomic) NSMutableArray *selectedObjects;

- (NSUInteger)countOfSelectedBones;
- (NSUInteger)countOfSelectedItems;
- (NSUInteger)countOfSelectedLights;
- (NSUInteger)countOfSelectedMeshes;
- (NSUInteger)countOfSelectedObjects;

- (NSManagedObject *)objectInSelectedLightsAtIndex:(NSUInteger)index;
- (GLLItem *)objectInSelectedItemsAtIndex:(NSUInteger)index;
- (GLLItemBone *)objectInSelectedBonesAtIndex:(NSUInteger)index;
- (GLLItemMesh *)objectInSelectedMeshesAtIndex:(NSUInteger)index;
- (NSManagedObject *)objectInSelectedObjectsAtIndex:(NSUInteger)index;

- (void)insertObject:(GLLItemBone *)object inSelectedBonesAtIndex:(NSUInteger)index;
- (void)insertObject:(GLLItem *)object inSelectedItemsAtIndex:(NSUInteger)index;
- (void)insertObject:(NSManagedObject *)object inSelectedLightsAtIndex:(NSUInteger)index;
- (void)insertObject:(GLLItemMesh *)object inSelectedMeshesAtIndex:(NSUInteger)index;
//- (void)insertObject:(NSManagedObject *)object inSelectedObjectsAtIndex:(NSUInteger)index;

- (void)removeObjectFromSelectedBonesAtIndex:(NSUInteger)index;
- (void)removeObjectFromSelectedItemsAtIndex:(NSUInteger)index;
- (void)removeObjectFromSelectedLightsAtIndex:(NSUInteger)index;
- (void)removeObjectFromSelectedMeshesAtIndex:(NSUInteger)index;
- (void)removeObjectFromSelectedObjectsAtIndex:(NSUInteger)index;

@end
