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
#import "GLLDirectionalLight.h"
#import "GLLDocumentWindowController.h"
#import "GLLRenderWindowController.h"

@interface GLLDocument ()
{
	GLLDocumentWindowController *documentWindowController;
	GLLRenderWindowController *renderWindowController;
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
		directionalLight.specularColor = [NSColor darkGrayColor];
		directionalLight.index = i + 1;
	}
	[self.managedObjectContext processPendingChanges];
	[self.managedObjectContext.undoManager enableUndoRegistration];
	
	return self;
}

- (void)makeWindowControllers
{
	documentWindowController = [[GLLDocumentWindowController alloc] initWithManagedObjectContext:self.managedObjectContext];
	[self addWindowController:documentWindowController];
	renderWindowController = [[GLLRenderWindowController alloc] initWithManagedObjectContext:self.managedObjectContext];
	[self addWindowController:renderWindowController];
}

@end
