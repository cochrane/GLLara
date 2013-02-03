//
//  GLLBoneController.m
//  GLLara
//
//  Created by Torsten Kammer on 01.01.13.
//  Copyright (c) 2013 Torsten Kammer. All rights reserved.
//

#import "GLLBoneController.h"

#import "GLLBoneListController.h"
#import "GLLItem.h"
#import "GLLItemBone.h"
#import "GLLModelBone.h"
#import "LionSubscripting.h"

@interface GLLBoneController ()

- (void)_updateObservers;

@property (nonatomic, readonly) NSArray *childBoneControllers;
@property (nonatomic) GLLBoneController *parentBoneController;
@property (nonatomic) NSMutableSet *observers;

@end

@implementation GLLBoneController

- (id)initWithBone:(GLLItemBone *)bone listController:(GLLBoneListController *)listController;
{
	if (!(self = [super init])) return nil;
	
	self.bone = bone;
	self.listController = listController;
	
	return self;
}

- (void)setBone:(GLLItemBone *)bone
{
	[_bone removeObserver:self forKeyPath:@"rotationX"];
	[_bone removeObserver:self forKeyPath:@"rotationY"];
	[_bone removeObserver:self forKeyPath:@"rotationZ"];
	[_bone removeObserver:self forKeyPath:@"locationX"];
	[_bone removeObserver:self forKeyPath:@"locationY"];
	[_bone removeObserver:self forKeyPath:@"locationZ"];
	
	_bone = bone;
	
	[_bone addObserver:self forKeyPath:@"rotationX" options:0 context:0];
	[_bone addObserver:self forKeyPath:@"rotationY" options:0 context:0];
	[_bone addObserver:self forKeyPath:@"rotationZ" options:0 context:0];
	[_bone addObserver:self forKeyPath:@"locationX" options:0 context:0];
	[_bone addObserver:self forKeyPath:@"locationY" options:0 context:0];
	[_bone addObserver:self forKeyPath:@"locationZ" options:0 context:0];
}

- (void)observeValueForKeyPath:(NSString *)keyPath ofObject:(id)object change:(NSDictionary *)change context:(void *)context
{
	if ([keyPath isEqual:@"rotationX"] || [keyPath isEqual:@"rotationY"] || [keyPath isEqual:@"rotationZ"] || [keyPath isEqual:@"locationX"] || [keyPath isEqual:@"locationY"] || [keyPath isEqual:@"locationZ"])
	{
		[self _updateObservers];
	}
	else
		[super observeValueForKeyPath:keyPath ofObject:object change:change context:context];
}

- (void)addBoneChangeObserver:(id <GLLBoneChangeListener>)observer;
{
	[self.observers addObject:observer];
}
- (void)removeBoneChangeObserver:(id <GLLBoneChangeListener>)observer;
{
	[self.observers removeObject:observer];
}

- (id)representedObject
{
	return self.bone;
}

- (id)parentController
{
	NSArray *parents = [self.listController.boneControllers filteredArrayUsingPredicate:[NSPredicate predicateWithFormat:@"%@ in bone.children", self.bone]];
	if (parents.count > 0) return parents[0];
	else return self.listController;
}

- (NSArray *)childBoneControllers
{
	return [self.listController.boneControllers filteredArrayUsingPredicate:[NSPredicate predicateWithFormat:@"bone.parent == %@", self.bone]];
}

#pragma mark - Outline View Data Source

- (id)outlineView:(NSOutlineView *)outlineView child:(NSInteger)index ofItem:(id)item
{
	return self.childBoneControllers[index];
}

- (id)outlineView:(NSOutlineView *)outlineView objectValueForTableColumn:(NSTableColumn *)tableColumn byItem:(id)item
{
	if (self.bone.item != self.listController.item)
		return [NSString stringWithFormat:NSLocalizedString(@"%@ (%@)", @"Bone from other model"), self.bone.bone.name, self.bone.item.displayName];
	else
		return self.bone.bone.name;
}

- (BOOL)outlineView:(NSOutlineView *)outlineView isItemExpandable:(id)item
{
	return self.childBoneControllers.count > 0;
}

- (NSInteger)outlineView:(NSOutlineView *)outlineView numberOfChildrenOfItem:(id)item
{
	return self.childBoneControllers.count;
}

#pragma mark - Bone Change Listener

- (void)boneDidChange:(GLLBoneController *)controller
{
	[self _updateObservers];
}

#pragma mark - Private methods

- (void)_updateObservers
{
	[self.observers makeObjectsPerformSelector:@selector(boneDidChange:) withObject:self];
}

@end
