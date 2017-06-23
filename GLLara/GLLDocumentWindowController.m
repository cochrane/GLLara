//
//  GLLDocumentWindowController.m
//  GLLara
//
//  Created by Torsten Kammer on 05.09.12.
//  Copyright (c) 2012 Torsten Kammer. All rights reserved.
//

#import "GLLDocumentWindowController.h"

#import "NSArray+Map.h"
#import "GLLAmbientLight.h"
#import "GLLAmbientLightViewController.h"
#import "GLLBoneViewController.h"
#import "GLLDirectionalLight.h"
#import "GLLDocument.h"
#import "GLLItem.h"
#import "GLLItem+OBJExport.h"
#import "GLLItemBone.h"
#import "GLLItemController.h"
#import "GLLItemExportViewController.h"
#import "GLLItemListController.h"
#import "GLLItemMesh.h"
#import "GLLItemViewController.h"
#import "GLLLightsListController.h"
#import "GLLLightViewController.h"
#import "GLLMeshViewController.h"
#import "GLLModel.h"
#import "GLLNoSelectionViewController.h"
#import "GLLSelection.h"
#import "GLLSettingsListController.h"

@interface GLLDocumentWindowController ()
{
    GLLNoSelectionViewController *noSelectionViewController;
    
    GLLAmbientLightViewController *ambientLightViewController;
    GLLBoneViewController *boneViewController;
    GLLItemViewController *itemViewController;
    GLLMeshViewController *meshViewController;
    GLLLightViewController *lightViewController;
    
    GLLLightsListController *lightsListController;
    GLLItemListController *itemListController;
    GLLSettingsListController *settingsListController;
    
    NSViewController *currentController;
    
    NSArrayController *selectionController;
    
    BOOL updatingSourceViewSelection;
    BOOL selectionUpdateFromSourceView;
}

- (void)_setRightHandController:(NSViewController *)controller;
- (void)_recursivelyExpandItem:(id)item;

@property (nonatomic, readonly) NSArray *allSelectableControllers;

@end

@implementation GLLDocumentWindowController

- (id)initWithManagedObjectContext:(NSManagedObjectContext *)managedObjectContext selection:(GLLSelection *)selection;
{
    if (!(self = [super initWithWindowNibName:@"GLLDocument"])) return nil;
    
    _managedObjectContext = managedObjectContext;
    _selection = selection;
    
    noSelectionViewController = [[GLLNoSelectionViewController alloc] init];
    
    ambientLightViewController = [[GLLAmbientLightViewController alloc] init];
    boneViewController = [[GLLBoneViewController alloc] init];
    itemViewController = [[GLLItemViewController alloc] init];
    meshViewController = [[GLLMeshViewController alloc] initWithSelection:_selection managedObjectContext:_managedObjectContext];
    lightViewController = [[GLLLightViewController alloc] init];
    
    selectionController = [[NSArrayController alloc] init];
    [selectionController bind:@"contentArray" toObject:self withKeyPath:@"selection.selectedObjects" options:nil];
    [self addObserver:self forKeyPath:@"selection.selectedObjects" options:NSKeyValueObservingOptionNew context:NULL];
    [[NSUserDefaults standardUserDefaults] addObserver:self forKeyPath:@"hideUnusedBones" options:NSKeyValueObservingOptionNew context:nil];
    
    self.shouldCloseDocument = YES;
    
    return self;
}

- (void)dealloc
{
    [itemViewController unbind:@"selectedItems"];
    [self removeObserver:self forKeyPath:@"selection.selectedObjects"];
    [[NSUserDefaults standardUserDefaults] removeObserver:self forKeyPath:@"hideUnusedBones"];
}

- (void)windowDidLoad
{
    [super windowDidLoad];
    
    lightsListController = [[GLLLightsListController alloc] initWithManagedObjectContext:self.managedObjectContext outlineView:self.sourceView];
    itemListController = [[GLLItemListController alloc] initWithManagedObjectContext:self.managedObjectContext outlineView:self.sourceView];
    settingsListController = [[GLLSettingsListController alloc] initWithManagedObjectContext:self.managedObjectContext outlineView:self.sourceView];
    
    self.sourceView.delegate = self;
    self.sourceView.dataSource = self;
    
    [self.sourceView expandItem:lightsListController];
    [self.sourceView expandItem:itemListController];
    [self.sourceView expandItem:settingsListController];
    
    [itemViewController bind:@"selectedItems" toObject:self.selection withKeyPath:@"selectedItems" options:nil];
    
    [self _setRightHandController:noSelectionViewController];
    
    [self.sourceView registerForDraggedTypes:@[ (__bridge NSString*) kUTTypeFileURL ]];
}

- (void)observeValueForKeyPath:(NSString *)keyPath ofObject:(id)object change:(NSDictionary *)change context:(void *)context
{
    if ([keyPath isEqual:@"selection.selectedObjects"])
    {
        // Ignore updates to selection that we essentially create ourselves
        if (selectionUpdateFromSourceView) return;
        
        // Set the correct selection in the outline view
        updatingSourceViewSelection = YES;
        
        NSArray *selectedOutlineViewItems = [self.allSelectableControllers filteredArrayUsingPredicate:[NSPredicate predicateWithFormat:@"representedObject in %@", self.selection.selectedObjects]];
        
        NSMutableIndexSet *selectionIndexes = [NSMutableIndexSet indexSet];
        for (id item in selectedOutlineViewItems)
        {
            [self _recursivelyExpandItem:item];
            [selectionIndexes addIndex:[self.sourceView rowForItem:item]];
        }
        
        [self.sourceView selectRowIndexes:selectionIndexes byExtendingSelection:NO];
        
        updatingSourceViewSelection = NO;
    } else if ([keyPath isEqual:@"hideUnusedBones"]) {
        [self.sourceView reloadData];
    }
}

#pragma mark - Core drag and drop

- (NSDragOperation)itemDraggingEntered:(id<NSDraggingInfo>)sender {
    GLLDocument *document = (GLLDocument *) self.document;
    if (!document) {
        return NSDragOperationNone;
    }
    
    NSPasteboard *pasteboard = sender.draggingPasteboard;
    for (NSPasteboardItem *item in pasteboard.pasteboardItems) {
        // Wait, does Apple really not have a method to get multiple URLs from
        // the pasteboard? I'm not complaining, just surprised.
        NSString *urlAsString = [item stringForType:(__bridge NSString*) kUTTypeFileURL];
        NSURL *url = [NSURL URLWithString:urlAsString].filePathURL;
        NSString *filename = url.lastPathComponent.lowercaseString;
        
        BOOL validFile = NO;
        // Check whether this is a model
        // Note: Not using dedicated methods because they can't deal with the
        // double extension that XNALara uses.
        if ([filename hasSuffix:@".mesh"] || [filename hasSuffix:@".mesh.ascii"] || [filename hasSuffix:@".xps"] || [filename hasSuffix:@".obj"]) {
            validFile = YES;
        }
        
        // Check whether this is an image path
        if ([self isImagePath:url.filePathURL]) {
            validFile = YES;
        }
        if (!validFile)
            return NSDragOperationNone;
    }
    
    return NSDragOperationCopy;
}

- (BOOL)isImagePath:(NSURL *)url {
    NSString *extension = url.pathExtension;
    if (!extension)
        return NO;
    
    // Check whether this is a DDS file
    if ([extension isEqualToString:@"dds"])
        return YES;
    
    // Try to find image type
    NSString *typeId = CFBridgingRelease(UTTypeCreatePreferredIdentifierForTag(kUTTagClassFilenameExtension, (__bridge CFStringRef) extension, kUTTypeImage));
    if (!typeId)
        return NO;
    
    NSArray *imageSourceTypes = (__bridge_transfer NSArray *) CGImageSourceCopyTypeIdentifiers();
    return [imageSourceTypes containsObject:typeId];
}

- (BOOL)performItemDragOperation:(id<NSDraggingInfo>)sender {
    GLLDocument *document = (GLLDocument *) self.document;
    if (!document) {
        return NO;
    }
    
    NSPasteboard *pasteboard = sender.draggingPasteboard;
    for (NSPasteboardItem *item in pasteboard.pasteboardItems) {
        // Wait, does Apple really not have a method to get multiple URLs from
        // the pasteboard? I'm not complaining, just surprised.
        NSString *urlAsString = [item stringForType:(__bridge NSString*) kUTTypeFileURL];
        NSURL *url = [NSURL URLWithString:urlAsString].filePathURL;
        
        NSError *error = nil;
        if ([self isImagePath:url]) {
            [document addImagePlane:url error:&error];
        } else {
            [document addModelAtURL:url error:&error];
        }
        if (error) {
            [self presentError:error];
            return NO;
        }
    }
    
    return YES;
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

- (void)outlineView:(NSOutlineView *)outlineView setObjectValue:(id)object forTableColumn:(NSTableColumn *)tableColumn byItem:(id)item
{
    if ([item respondsToSelector:_cmd])
        [item outlineView:outlineView setObjectValue:object forTableColumn:tableColumn byItem:item];
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

- (NSDragOperation)outlineView:(NSOutlineView *)outlineView validateDrop:(nonnull id<NSDraggingInfo>)info proposedItem:(nullable id)item proposedChildIndex:(NSInteger)index {
    if (!(item == itemListController))
        return NSDragOperationNone;
    
    return [self itemDraggingEntered:info];
}

- (BOOL)outlineView:(NSOutlineView *)outlineView acceptDrop:(nonnull id<NSDraggingInfo>)info item:(nullable id)item childIndex:(NSInteger)index {
    return [self performItemDragOperation:info];
}

#pragma mark - Outline view delegate

- (BOOL)outlineView:(NSOutlineView *)outlineView isGroupItem:(id)item
{
    if ([item respondsToSelector:_cmd])
        return [item outlineView:outlineView isGroupItem:item];
    return NO;
}

- (NSIndexSet *)outlineView:(NSOutlineView *)outlineView selectionIndexesForProposedSelection:(NSIndexSet *)proposedSelectionIndexes;
{
    Class firstClass = Nil;
    
    for (NSUInteger index = proposedSelectionIndexes.firstIndex; index <= proposedSelectionIndexes.lastIndex; index = [proposedSelectionIndexes indexGreaterThanIndex:index])
    {
        id item = [outlineView itemAtRow:index];
        
        // Check whether item does not want to be selected
        if ([item respondsToSelector:@selector(outlineView:shouldSelectItem:)])
        {
            if (![item outlineView:outlineView shouldSelectItem:item])
                return outlineView.selectedRowIndexes;
        }
        
        Class current = [item class];
        if (!firstClass) firstClass = current;
        if (firstClass != current) return outlineView.selectedRowIndexes;
    }
    
    return proposedSelectionIndexes;
}

- (BOOL)outlineView:(NSOutlineView *)outlineView shouldEditTableColumn:(NSTableColumn *)tableColumn item:(id)item
{
    if ([item respondsToSelector:_cmd])
        return [item outlineView:outlineView shouldEditTableColumn:tableColumn item:item];
    return NO;
}

- (void)outlineViewSelectionDidChange:(NSNotification *)notification
{
    selectionUpdateFromSourceView = YES;
    
    NSArray *newSelectedObjects = [self.sourceView.selectedRowIndexes map:^(NSUInteger index){
        return [[self.sourceView itemAtRow:index] representedObject];
    }];
    
    if (!updatingSourceViewSelection)
    {
        NSMutableArray *selectedObjects = [self.selection mutableArrayValueForKey:@"selectedObjects"];
        [selectedObjects removeObjectsAtIndexes:[NSIndexSet indexSetWithIndexesInRange:NSMakeRange(0, selectedObjects.count)]];
        [selectedObjects insertObjects:newSelectedObjects atIndexes:[NSIndexSet indexSetWithIndexesInRange:NSMakeRange(0, newSelectedObjects.count)]];
    }
    
    [selectionController setSelectedObjects:selectionController.arrangedObjects];
    
    if (newSelectedObjects.count == 0)
        [self _setRightHandController:nil];
    else
    {
        NSManagedObject *oneOfSelection = newSelectedObjects.lastObject;
        if ([oneOfSelection.entity isKindOfEntity:[NSEntityDescription entityForName:@"GLLAmbientLight" inManagedObjectContext:self.managedObjectContext]])
            [self _setRightHandController:ambientLightViewController];
        else if ([oneOfSelection.entity isKindOfEntity:[NSEntityDescription entityForName:@"GLLDirectionalLight" inManagedObjectContext:self.managedObjectContext]])
            [self _setRightHandController:lightViewController];
        else if ([oneOfSelection.entity isKindOfEntity:[NSEntityDescription entityForName:@"GLLItem" inManagedObjectContext:self.managedObjectContext]])
            [self _setRightHandController:itemViewController];
        else if ([oneOfSelection.entity isKindOfEntity:[NSEntityDescription entityForName:@"GLLItemMesh" inManagedObjectContext:self.managedObjectContext]])
            [self _setRightHandController:meshViewController];
        else if ([oneOfSelection.entity isKindOfEntity:[NSEntityDescription entityForName:@"GLLItemBone" inManagedObjectContext:self.managedObjectContext]])
            [self _setRightHandController:boneViewController];
        else
            [self _setRightHandController:nil];
    }
    
    selectionUpdateFromSourceView = NO;
}

#pragma mark - Private methods

- (void)_setRightHandController:(NSViewController *)controller;
{
    /*
     * This code first sets the represented object to nil, then to the selection, even if nothing seems to have changed. This is because otherwise, the object controllers don't notice that the contents of the selection of the array controller has changed (Someone should really write a bug report about this, by the way). Setting it again to the original value will be ignored, so it has to be set to something else (like nil) in between.
     */
    currentController.representedObject = nil;
    
    if (currentController == controller)
    {
        currentController.representedObject = [selectionController selection];
        return;
    }
    
    if (currentController)
    {
        [currentController.view removeFromSuperview];
        currentController = nil;
    }
    
    if (controller)
    {
        NSView *newView = controller.view;
        newView.frame = (NSRect) { { 0.0f, 0.0f }, self.placeholderView.frame.size };
        [self.placeholderView addSubview:controller.view];
        controller.representedObject = selectionController.selection;
        currentController = controller;
    }
}

- (void)_recursivelyExpandItem:(id)item;
{
    if ([item respondsToSelector:@selector(parentController)])
        [self _recursivelyExpandItem:[item parentController]];
    [self.sourceView expandItem:item];
}

- (NSArray *)allSelectableControllers
{
    NSMutableArray *result = [NSMutableArray array];
    [result addObjectsFromArray:lightsListController.allSelectableControllers];
    [result addObjectsFromArray:itemListController.allSelectableControllers];
    [result addObjectsFromArray:settingsListController.allSelectableControllers];
    return result;
}

@end
