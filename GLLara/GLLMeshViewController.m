//
//  GLLMeshViewController.m
//  GLLara
//
//  Created by Torsten Kammer on 06.09.12.
//  Copyright (c) 2012 Torsten Kammer. All rights reserved.
//

#import "GLLMeshViewController.h"

#import "GLLFloatRenderParameterView.h"
#import "GLLItemMesh.h"
#import "GLLRenderParameter.h"
#import "GLLRenderParameterDescription.h"

@interface GLLMeshViewController ()
{
	NSArray *renderParameterNames;
	NSArrayController *renderParameters;
}

- (void)_findRenderParameterNames;

@end

@implementation GLLMeshViewController

- (id)init
{
	if (!(self = [super initWithNibName:@"GLLMeshView" bundle:[NSBundle mainBundle]]))
		return nil;
	
	renderParameters = [[NSArrayController alloc] init];
	
	return self;
}

-(NSView *)tableView:(NSTableView *)tableView viewForTableColumn:(NSTableColumn *)tableColumn row:(NSInteger)row
{
	NSString *parameterName = [renderParameterNames objectAtIndex:row];
	
	GLLRenderParameterDescription *descriptionForName = nil;
	for (GLLItemMesh *mesh in self.selectedObjects)
	{
		descriptionForName = [mesh renderParameterWithName:parameterName].parameterDescription;
		if (descriptionForName) break;
	}
	
	if (!descriptionForName)
		return nil;
	
	if ([descriptionForName.type isEqual:GLLRenderParameterTypeColor])
		return [tableView makeViewWithIdentifier:@"ColorRenderParameterView" owner:self];
	else if ([descriptionForName.type isEqual:GLLRenderParameterTypeFloat])
	{
		GLLFloatRenderParameterView *result = [tableView makeViewWithIdentifier:@"FloatRenderParameterView" owner:self];
		
		[result.parameterTitle bind:@"value" toObject:renderParameters withKeyPath:[NSString stringWithFormat:@"selection.%@.parameterDescription.localizedTitle", parameterName] options:nil];
		[result.parameterDescription bind:@"value" toObject:renderParameters withKeyPath:[NSString stringWithFormat:@"selection.%@.parameterDescription.localizedDescription", parameterName] options:nil];
		[result.parameterSlider bind:@"minValue" toObject:renderParameters withKeyPath:[NSString stringWithFormat:@"selection.%@.parameterDescription.min", parameterName] options:nil];
		[result.parameterSlider bind:@"maxValue" toObject:renderParameters withKeyPath:[NSString stringWithFormat:@"selection.%@.parameterDescription.max", parameterName] options:nil];
		[result.parameterSlider bind:@"value" toObject:renderParameters withKeyPath:[NSString stringWithFormat:@"selection.%@.value", parameterName] options:nil];
		[result.parameterValueField bind:@"value" toObject:renderParameters withKeyPath:[NSString stringWithFormat:@"selection.%@.value", parameterName] options:nil];
		
		return result;
	}
	else
		return nil;
}

- (void)setSelectedObjects:(NSArray *)selectedObjects
{
	if (self.representedObject == nil) return;
	
	_selectedObjects = selectedObjects;
	
	[self _findRenderParameterNames];
	[self.renderParametersView reloadData];
}

- (void)setRepresentedObject:(id)representedObject
{
	[super setRepresentedObject:representedObject];
	
	[self _findRenderParameterNames];
}

- (NSInteger)numberOfRowsInTableView:(NSTableView *)tableView
{
	return renderParameterNames.count;
}
- (id)tableView:(NSTableView *)tableView objectValueForTableColumn:(NSTableColumn *)tableColumn row:(NSInteger)row
{
	// representedObject is a selection proxy, pointing to GLLItemMesh objects
	NSString *parameterName = [renderParameterNames objectAtIndex:row];
	return [renderParameters.selection valueForKeyPath:parameterName];
}

#pragma mark - Private methods

- (void)_findRenderParameterNames;
{
	if (self.selectedObjects.count == 0)
	{
		renderParameterNames = @[];
		return;
	}
	
	// Compute intersection of parameter names
	NSMutableSet *parameterNames = [[self.selectedObjects[0] valueForKeyPath:@"renderParameters.name"] mutableCopy];
	
	for (GLLItemMesh *mesh in self.selectedObjects)
		[parameterNames intersectSet:[mesh valueForKeyPath:@"renderParameters.name"]];
	
	renderParameterNames = [parameterNames sortedArrayUsingDescriptors:@[ [NSSortDescriptor sortDescriptorWithKey:@"self" ascending:YES] ] ];
	
	renderParameters.content = self.selectedObjects;
	renderParameters.selectedObjects = self.selectedObjects;
	
	[self.renderParametersView reloadData];
}

@end
