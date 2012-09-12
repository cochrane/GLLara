//
//  GLLMeshSettingsViewController.m
//  GLLara
//
//  Created by Torsten Kammer on 06.09.12.
//  Copyright (c) 2012 Torsten Kammer. All rights reserved.
//

#import "GLLMeshSettingsViewController.h"

#import "GLLMeshSettings.h"
#import "GLLRenderParameterDescription.h"

@interface GLLMeshSettingsViewController ()

@end

@implementation GLLMeshSettingsViewController

- (id)init
{
	if (!(self = [super initWithNibName:@"GLLMeshSettingsViewController" bundle:[NSBundle mainBundle]]))
		return nil;
	
	return self;
}

-(NSView *)tableView:(NSTableView *)tableView viewForTableColumn:(NSTableColumn *)tableColumn row:(NSInteger)row
{
	NSArray *renderParameters = [[(GLLMeshSettings *) self.representedObject renderParameters] sortedArrayUsingDescriptors:@[ [NSSortDescriptor sortDescriptorWithKey:@"name" ascending:YES] ]];
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
	NSArray *renderParameters = [[(GLLMeshSettings *) self.representedObject renderParameters] sortedArrayUsingDescriptors:@[ [NSSortDescriptor sortDescriptorWithKey:@"name" ascending:YES] ]];
	
	return [renderParameters objectAtIndex:row];
}

@end
