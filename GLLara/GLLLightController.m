//
//  GLLLightController.m
//  GLLara
//
//  Created by Torsten Kammer on 13.01.13.
//  Copyright (c) 2013 Torsten Kammer. All rights reserved.
//

#import "GLLLightController.h"

@implementation GLLLightController

- (id)initWithLight:(NSManagedObject *)light;
{
    if (!(self = [super init])) return nil;
    
	_light = light;
	
	return self;
}

- (id)representedObject
{
	return self.light;
}

#pragma mark - Outline view data source

- (id)outlineView:(NSOutlineView *)outlineView child:(NSInteger)index ofItem:(id)item
{
	return nil;
}

- (id)outlineView:(NSOutlineView *)outlineView objectValueForTableColumn:(NSTableColumn *)tableColumn byItem:(id)item
{
	if ([self.light.entity.name isEqual:@"GLLAmbientLight"])
		return NSLocalizedString(@"Ambient", @"source view - lights");
	else
		return [NSString stringWithFormat:NSLocalizedString(@"Diffuse %@", @"source view - lights"), [self.light valueForKey:@"index"]];
}

- (BOOL)outlineView:(NSOutlineView *)outlineView isItemExpandable:(id)item
{
	return NO;
}

- (NSInteger)outlineView:(NSOutlineView *)outlineView numberOfChildrenOfItem:(id)item
{
	return 0;
}

@end
