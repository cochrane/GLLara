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

@interface GLLMeshViewController ()
{
	NSArray *renderParameterNames;
}

@end

@implementation GLLMeshViewController

- (id)init
{
	if (!(self = [super initWithNibName:@"GLLMeshView" bundle:[NSBundle mainBundle]]))
		return nil;
	
	return self;
}

-(NSView *)tableView:(NSTableView *)tableView viewForTableColumn:(NSTableColumn *)tableColumn row:(NSInteger)row
{
	NSString *parameterName = [renderParameterNames objectAtIndex:row];
	id object = [self.representedObject valueForKeyPath:parameterName];

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
	
	renderParameterNames = [[representedObject valueForKeyPath:@"renderParameters.name"] sortedArrayUsingDescriptors:@[ [NSSortDescriptor sortDescriptorWithKey:@"self" ascending:YES] ] ];
	
	[self.renderParametersView reloadData];
}

- (NSInteger)numberOfRowsInTableView:(NSTableView *)tableView
{
	return renderParameterNames.count;
}
- (id)tableView:(NSTableView *)tableView objectValueForTableColumn:(NSTableColumn *)tableColumn row:(NSInteger)row
{
	// representedObject is a selection proxy, pointing to GLLItemMesh objects
	NSString *parameterName = [renderParameterNames objectAtIndex:row];
	return [self.representedObject valueForKeyPath:parameterName];
}

@end
