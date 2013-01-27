//
//  GLLLightsListController.m
//  GLLara
//
//  Created by Torsten Kammer on 13.01.13.
//  Copyright (c) 2013 Torsten Kammer. All rights reserved.
//

#import "GLLLightsListController.h"

#import "GLLLightController.h"
#import "LionSubscripting.h"
#import "NSArray+Map.h"

@interface GLLLightsListController ()

@property (nonatomic) NSArray *lights;
- (void)_fetchLights;

@end

@implementation GLLLightsListController

- (id)initWithManagedObjectContext:(NSManagedObjectContext *)managedObjectContext outlineView:(NSOutlineView *)outlineView;
{
    if (!(self = [super init])) return nil;
    
	_managedObjectContext = managedObjectContext;
	_outlineView = outlineView;
		
	return self;
}

- (NSArray *)allSelectableControllers
{
	return self.lights;
}

#pragma mark - Outline view data source

- (id)outlineView:(NSOutlineView *)outlineView child:(NSInteger)index ofItem:(id)item
{
	if (!self.lights) [self _fetchLights];
	return self.lights[index];
}

- (id)outlineView:(NSOutlineView *)outlineView objectValueForTableColumn:(NSTableColumn *)tableColumn byItem:(id)item
{
	if (item == self) return NSLocalizedString(@"Lights", @"source view header");
	
	if ([[item valueForKeyPath:@"entity.name"] isEqual:@"GLLAmbientLight"])
		return NSLocalizedString(@"Ambient", @"source view - lights");
	else
		return [NSString stringWithFormat:NSLocalizedString(@"Diffuse %@", @"source view - lights"), [item valueForKey:@"index"]];
}

- (BOOL)outlineView:(NSOutlineView *)outlineView isItemExpandable:(id)item
{
	return YES;
}

- (NSInteger)outlineView:(NSOutlineView *)outlineView numberOfChildrenOfItem:(id)item
{
	if (!self.lights) [self _fetchLights];
	return self.lights.count;
}

#pragma mark - Outline view delegate

- (BOOL)outlineView:(NSOutlineView *)outlineView isGroupItem:(id)item
{
	return YES;
}

- (BOOL)outlineView:(NSOutlineView *)outlineView shouldSelectItem:(id)item
{
	return NO;
}

#pragma mark - Private methods

- (void)_fetchLights;
{
	NSFetchRequest *lightsRequest = [NSFetchRequest fetchRequestWithEntityName:@"GLLLight"];
	lightsRequest.sortDescriptors = @[ [NSSortDescriptor sortDescriptorWithKey:@"index" ascending:YES] ];
	
	NSArray *lightEntities = [self.managedObjectContext executeFetchRequest:lightsRequest error:NULL];
	
	self.lights = [lightEntities map:^(NSManagedObject *light){
		return [[GLLLightController alloc] initWithLight:light parentController:self];
	}];
}

@end
