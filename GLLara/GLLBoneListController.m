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

@property (nonatomic) NSArray *rootBoneControllers;
@property (nonatomic, readwrite) NSArray *boneControllers;

@end

@implementation GLLBoneListController

- (id)initWithItem:(GLLItem *)item parent:(id)parentController;
{
	if (!(self = [super init])) return nil;
	
	self.item = item;
	self.parentController = parentController;
	
	self.boneControllers = [self.item.bones map:^(GLLItemBone *bone){
		return [[GLLBoneController alloc] initWithBone:bone listController:self];
	}];
	self.rootBoneControllers = [self.boneControllers filteredArrayUsingPredicate:[NSPredicate predicateWithFormat:@"bone.parent == NULL"]];
	
	return self;
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
