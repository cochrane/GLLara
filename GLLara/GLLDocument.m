//
//  GLLDocument.m
//  GLLara
//
//  Created by Torsten Kammer on 31.08.12.
//  Copyright (c) 2012 Torsten Kammer. All rights reserved.
//

#import "GLLDocument.h"

#import "GLLAmbientLight.h"
#import "GLLAngleRangeValueTransformer.h"
#import "GLLCamera.h"
#import "GLLDirectionalLight.h"
#import "GLLDocumentWindowController.h"
#import "GLLRenderWindowController.h"

@interface GLLDocument ()
{
	GLLDocumentWindowController *documentWindowController;
}

@end

@implementation GLLDocument

+ (void)initialize
{
	[NSValueTransformer setValueTransformer:[[GLLAngleRangeValueTransformer alloc] init] forName:@"GLLAngleRangeValueTransformer"];
}

- (id)initWithType:(NSString *)typeName error:(NSError **)outError
{
	if (!(self = [super initWithType:typeName error:outError]))
		return nil;
	
	[self.managedObjectContext processPendingChanges];
	[self.managedObjectContext.undoManager disableUndoRegistration];
	// Prepare the default lights
	
	// One ambient light
	GLLAmbientLight *ambientLight = [NSEntityDescription insertNewObjectForEntityForName:@"GLLAmbientLight" inManagedObjectContext:self.managedObjectContext];
	ambientLight.color = [NSColor darkGrayColor];
	ambientLight.index = 0;
	
	// Three directional lights.
	for (int i = 0; i < 3; i++)
	{
		GLLDirectionalLight *directionalLight = [NSEntityDescription insertNewObjectForEntityForName:@"GLLDirectionalLight" inManagedObjectContext:self.managedObjectContext];
		directionalLight.isEnabled = (i == 0);
		directionalLight.diffuseColor = [NSColor whiteColor];
		directionalLight.specularColor = [NSColor whiteColor];
		directionalLight.index = i + 1;
	}
	
	// Prepare standard camera
	[NSEntityDescription insertNewObjectForEntityForName:@"GLLCamera" inManagedObjectContext:self.managedObjectContext];
	
	[self.managedObjectContext processPendingChanges];
	[self.managedObjectContext.undoManager enableUndoRegistration];
	
	return self;
}

- (void)makeWindowControllers
{
	documentWindowController = [[GLLDocumentWindowController alloc] initWithManagedObjectContext:self.managedObjectContext];
	[self addWindowController:documentWindowController];

	NSFetchRequest *camerasFetchRequest = [[NSFetchRequest alloc] init];
	camerasFetchRequest.entity = [NSEntityDescription entityForName:@"GLLCamera" inManagedObjectContext:self.managedObjectContext];
	camerasFetchRequest.sortDescriptors = @[ [NSSortDescriptor sortDescriptorWithKey:@"index" ascending:YES] ];
	NSArray *cameras = [self.managedObjectContext executeFetchRequest:camerasFetchRequest error:NULL];
	
	for (GLLCamera *camera in cameras)
	{
		GLLRenderWindowController *controller = [[GLLRenderWindowController alloc] initWithCamera:camera];
		[self addWindowController:controller];
	}
}

- (IBAction)openNewRenderView:(id)sender
{
	// 1st: Find an index for the new render view.
	NSFetchRequest *highestIndexRequest = [[NSFetchRequest alloc] init];
	highestIndexRequest.entity = [NSEntityDescription entityForName:@"GLLCamera" inManagedObjectContext:self.managedObjectContext];
	highestIndexRequest.sortDescriptors = @[ [NSSortDescriptor sortDescriptorWithKey:@"index" ascending:NO] ];
	highestIndexRequest.fetchLimit = 1;
	NSArray *highestCameras = [self.managedObjectContext executeFetchRequest:highestIndexRequest error:NULL];
	NSUInteger index;
	if (highestCameras.count > 0)
		index = [[highestCameras objectAtIndex:0] index] + 1;
	else
		index = 0;
	
	// 2nd: Create that camera object
	GLLCamera *camera = [NSEntityDescription insertNewObjectForEntityForName:@"GLLCamera" inManagedObjectContext:self.managedObjectContext];
	camera.index = index;
	
	// 3rd: Create its window controller
	GLLRenderWindowController *controller = [[GLLRenderWindowController alloc] initWithCamera:camera];
	[self addWindowController:controller];
	[controller showWindow:sender];
}

@end
