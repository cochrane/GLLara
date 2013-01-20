//
//  GLLMeshViewController.m
//  GLLara
//
//  Created by Torsten Kammer on 06.09.12.
//  Copyright (c) 2012 Torsten Kammer. All rights reserved.
//

#import "GLLMeshViewController.h"

#import "GLLColorRenderParameterView.h"
#import "GLLFloatRenderParameterView.h"
#import "GLLItemMesh.h"
#import "GLLRenderParameter.h"
#import "GLLRenderParameterDescription.h"

/************************************************************************
 A very high-level overview:
 
 I have an array controller, whose content is dependent on the selection
 of a tree controller (but not direclty set to; the view-based table
 view didn't work as I wanted it, so I'm rolling my own). The mesh
 objects of the tree controller have parameters with names that are
 unique per mesh, but most meshes wil have parameters of the same
 values. Each entry in the table view allows me to edit one parameter. I
 want that each table view cell can edit the values for multiple
 selection.
 
 Any straightforward implementation is hampered by the fact that you can
 only bind things directly to  a key path containing "selection", you
 can't go through anything that is bound to "selection". To solve this,
 
 a) This controller gets the "selection" proxy as a representedObject,
 with the selectedObjects array as generic fallbac
 b) The items of the view are bound more or less directly to self.
 
 The more or less is what I hate the most; binding directly to selection
 won't work (not sure why), so I've got an array controller set to
 selected objects, all selected, and am using that controller's
 selection proxy for the binding. It works, but I'm really looking for a
 cleaner solution.
 
 Binding something to a specific index in an array (or set!) won't work,
 of course, but I know that each object has its own key here, and that
 two will have the same key if I want to display them together. So with
 some slight hackery, I am using that key as a key for KVC, and bind to
 it. You don't expect to see stringWithFormat… in any KVC or bindings
 code, but this solution doesn't rely on anything undocumented and works.
 
 Getting access to the view is also surprisingly difficult. I have no
 idea what the "owner" parameter does, but it's not what I want it to;
 it doesn't set my outlets. So instead I'm using an NSView subclass that
 contains the outlets to the individual fields. That works. Binding in
 IB is out of the question due to the trick with the dynamically
 generated key path.
 ************************************************************************/

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
	for (GLLItemMesh *mesh in self.selectedMeshes)
	{
		descriptionForName = [mesh renderParameterWithName:parameterName].parameterDescription;
		if (descriptionForName) break;
	}
	
	if (!descriptionForName)
		return nil;
	
	if ([descriptionForName.type isEqual:GLLRenderParameterTypeColor])
	{
		GLLColorRenderParameterView *result = [tableView makeViewWithIdentifier:@"ColorRenderParameterView" owner:self];
		
		[result.parameterTitle bind:@"value" toObject:renderParameters withKeyPath:[NSString stringWithFormat:@"selection.%@.parameterDescription.localizedTitle", parameterName] options:nil];
		[result.parameterDescription bind:@"value" toObject:renderParameters withKeyPath:[NSString stringWithFormat:@"selection.%@.parameterDescription.localizedDescription", parameterName] options:nil];
		[result.parameterValue bind:@"value" toObject:renderParameters withKeyPath:[NSString stringWithFormat:@"selection.%@.value", parameterName] options:nil];
		
		return result;
		
	}
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

- (void)setSelectedMeshes:(NSArray *)selectedMeshes
{
	_selectedMeshes = selectedMeshes;
	
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
	NSString *parameterName = [renderParameterNames objectAtIndex:row];
	return [renderParameters.selection valueForKeyPath:parameterName];
}

#pragma mark - Private methods

- (void)_findRenderParameterNames;
{
	if (self.selectedMeshes.count == 0)
	{
		renderParameterNames = @[];
		return;
	}
	
	// Compute intersection of parameter names
	NSMutableSet *parameterNames = [[self.selectedMeshes[0] valueForKeyPath:@"renderParameters.name"] mutableCopy];
	
	for (GLLItemMesh *mesh in self.selectedMeshes)
		[parameterNames intersectSet:[mesh valueForKeyPath:@"renderParameters.name"]];
	
	renderParameterNames = [parameterNames sortedArrayUsingDescriptors:@[ [NSSortDescriptor sortDescriptorWithKey:@"self" ascending:YES] ] ];
	
	renderParameters.content = self.selectedMeshes;
	renderParameters.selectedObjects = self.selectedMeshes;
	
	[self.renderParametersView reloadData];
}

@end
