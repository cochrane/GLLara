//
//  GLLSubItemController.m
//  GLLara
//
//  Created by Torsten Kammer on 03.02.13.
//  Copyright (c) 2013 Torsten Kammer. All rights reserved.
//

#import "GLLSubItemController.h"

#import "GLLMeshListController.h"
#import "LionSubscripting.h"

@implementation GLLSubItemController

- (NSArray *)allSelectableControllers
{
	NSMutableArray *result = [NSMutableArray arrayWithObject:self];
	[result addObjectsFromArray:self.meshListController.allSelectableControllers];
	return result;
}

#pragma mark - Outline View Data Source

- (id)outlineView:(NSOutlineView *)outlineView child:(NSInteger)index ofItem:(id)item
{
	switch (index)
	{
		case 0: return self.meshListController;
		default: return self.childrenControllers[index - 1];
	}
}

- (NSInteger)outlineView:(NSOutlineView *)outlineView numberOfChildrenOfItem:(id)item
{
	return 1 + self.childrenControllers.count;
}


@end
