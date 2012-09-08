//
//  GLLDocument.m
//  GLLara
//
//  Created by Torsten Kammer on 31.08.12.
//  Copyright (c) 2012 Torsten Kammer. All rights reserved.
//

#import "GLLDocument.h"

#import "GLLAngleRangeValueTransformer.h"
#import "GLLDocumentWindowController.h"
#import "GLLItem.h"
#import "GLLModel.h"
#import "GLLRenderWindowController.h"
#import "GLLSceneDrawer.h"
#import "GLLView.h"

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

- (void)makeWindowControllers
{
	documentWindowController = [[GLLDocumentWindowController alloc] initWithManagedObjectContext:self.managedObjectContext];
	[self addWindowController:documentWindowController];
	renderWindowController = [[GLLRenderWindowController alloc] initWithManagedObjectContext:self.managedObjectContext];
	[self addWindowController:renderWindowController];
}

@end
