//
//  GLLBoneListController.m
//  GLLara
//
//  Created by Torsten Kammer on 13.01.13.
//  Copyright (c) 2013 Torsten Kammer. All rights reserved.
//

#import "GLLBoneListController.h"

#import "NSArray+Map.h"
#import "GLLItem.h"
#import "GLLBoneController.h"

@interface GLLBoneListController ()

@property (nonatomic) NSArray<GLLBoneController *> *rootBoneControllers;
@property (nonatomic, readwrite) NSMutableArray<GLLBoneController *> *boneControllers;

@end

@implementation GLLBoneListController

- (id)initWithItem:(GLLItem *)item outlineView:(NSOutlineView *)outlineView parent:(id)parentController;
{
	if (!(self = [super init])) return nil;
	
	self.item = item;
	self.parentController = parentController;
	_outlineView = outlineView;
	
	self.boneControllers = [[self.item.combinedBones map:^(GLLItemBone *bone){
		return [[GLLBoneController alloc] initWithBone:bone listController:self];
	}] mutableCopy];
	self.rootBoneControllers = [self.boneControllers filteredArrayUsingPredicate:[NSPredicate predicateWithFormat:@"bone.parent == NULL"]];
	
	[self.item addObserver:self forKeyPath:@"childItems" options:NSKeyValueObservingOptionNew | NSKeyValueObservingOptionOld | NSKeyValueObservingOptionInitial context:NULL];
	
	return self;
}

- (void)dealloc
{
	[self.item removeObserver:self forKeyPath:@"childItems"];
}

- (void)observeValueForKeyPath:(NSString *)keyPath ofObject:(id)object change:(NSDictionary *)change context:(void *)context
{
	if ([keyPath isEqual:@"childItems"])
	{
		// Observe the children of the new items, too, and remove observing for old ones
		if (![change[NSKeyValueChangeOldKey] isKindOfClass:[NSNull class]])
			for (GLLItem *item in change[NSKeyValueChangeOldKey])
				[item removeObserver:self forKeyPath:@"childItems"];
		
		if (![change[NSKeyValueChangeNewKey] isKindOfClass:[NSNull class]])
			for (GLLItem *item in change[NSKeyValueChangeNewKey])
				[item addObserver:self forKeyPath:@"childItems" options: NSKeyValueObservingOptionInitial context:NULL];
		
		// Run only after delay, to ensure that everything has been set correctly by the time this code gets active.
		dispatch_async(dispatch_get_main_queue(), ^{
			NSOrderedSet<GLLItemBone *> *newBones = self.item.combinedBones;
			
			// Find existing bones
			NSOrderedSet<GLLItemBone *> *existingBones = [NSOrderedSet orderedSetWithArray:[self.boneControllers valueForKeyPath:@"bone"]];
			
			// Remove bone controllers not in the old list
			NSMutableOrderedSet<GLLItemBone *> *deleted = [NSMutableOrderedSet orderedSetWithOrderedSet:existingBones];
			[deleted minusOrderedSet:newBones];
			
			NSIndexSet *indicesOfDeletedBoneControllers = [self.boneControllers indexesOfObjectsPassingTest:^(GLLBoneController *boneController, NSUInteger idx, BOOL *stop){
				return [deleted containsObject:boneController.bone];
			}];
			[self.boneControllers removeObjectsAtIndexes:indicesOfDeletedBoneControllers];
			
			// Add bone controllers in the new list
			NSMutableOrderedSet<GLLItemBone *> *added = [NSMutableOrderedSet orderedSetWithOrderedSet:newBones];
			[added minusOrderedSet:existingBones];
			[self.boneControllers addObjectsFromArray:[added map:^(GLLItemBone *bone){
				return [[GLLBoneController alloc] initWithBone:bone listController:self];
			}]];
			
			// Update
			self.rootBoneControllers = [self.boneControllers filteredArrayUsingPredicate:[NSPredicate predicateWithFormat:@"bone.parent == NULL"]];
			[self.outlineView reloadItem:self reloadChildren:YES];
		});
	}
}

- (NSArray *)allSelectableControllers
{
	return self.boneControllers;
}

#pragma mark - Outline View Data Source

- (id)outlineView:(NSOutlineView *)outlineView child:(NSInteger)index ofItem:(id)item
{
	return self.rootBoneControllers[index];
}

- (id)outlineView:(NSOutlineView *)outlineView objectValueForTableColumn:(NSTableColumn *)tableColumn byItem:(id)item
{
	return NSLocalizedString(@"Bones", @"source view header");
}

- (BOOL)outlineView:(NSOutlineView *)outlineView isItemExpandable:(id)item
{
	return YES;
}

- (NSInteger)outlineView:(NSOutlineView *)outlineView numberOfChildrenOfItem:(id)item
{
	return self.rootBoneControllers.count;
}

#pragma mark - Outline View Delegate

- (BOOL)outlineView:(NSOutlineView *)outlineView shouldSelectItem:(id)item
{
	return NO;
}

@end
