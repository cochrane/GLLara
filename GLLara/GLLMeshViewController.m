//
//  GLLMeshViewController.m
//  GLLara
//
//  Created by Torsten Kammer on 06.09.12.
//  Copyright (c) 2012 Torsten Kammer. All rights reserved.
//

#import "GLLMeshViewController.h"

#import "GLLItemMesh.h"
#import "GLLRenderParameterDescription.h"

@implementation GLLMeshViewController

- (id)init
{
	if (!(self = [super initWithNibName:@"GLLMeshViewController" bundle:[NSBundle mainBundle]]))
		return nil;
	
	return self;
}

-(NSView *)tableView:(NSTableView *)tableView viewForTableColumn:(NSTableColumn *)tableColumn row:(NSInteger)row
{
	NSArray *renderParameters = [[(GLLItemMesh *) self.representedObject renderParameters] sortedArrayUsingDescriptors:@[ [NSSortDescriptor sortDescriptorWithKey:@"name" ascending:YES] ]];
	if ((NSUInteger) row >= renderParameters.count)
		return nil;
	
	id object = renderParameters[row];
	if ([[object valueForKeyPath:@"parameterDescription.type"] isEqual:GLLRenderParameterTypeColor])
		return [tableView makeViewWithIdentifier:@"ColorRenderParameterView" owner:self];
	else if ([[object valueForKeyPath:@"parameterDescription.type"] isEqual:GLLRenderParameterTypeFloat])
		return [tableView makeViewWithIdentifier:@"FloatRenderParameterView" owner:self];
	else
		return nil;
}

- (void)setRepresentedObject:(id)representedObject
{
	[super setRepresentedObject:representedObject];
	[self.renderParametersView reloadData];
}

- (NSInteger)numberOfRowsInTableView:(NSTableView *)tableView
{
	return [[self.representedObject renderParameters] count];
}
- (id)tableView:(NSTableView *)tableView objectValueForTableColumn:(NSTableColumn *)tableColumn row:(NSInteger)row
{
	NSArray *renderParameters = [[(GLLItemMesh *) self.representedObject renderParameters] sortedArrayUsingDescriptors:@[ [NSSortDescriptor sortDescriptorWithKey:@"name" ascending:YES] ]];
	
	return [renderParameters objectAtIndex:row];
}

@end
