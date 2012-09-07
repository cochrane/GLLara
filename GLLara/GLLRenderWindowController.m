//
//  GLLRenderWindowController.m
//  GLLara
//
//  Created by Torsten Kammer on 05.09.12.
//  Copyright (c) 2012 Torsten Kammer. All rights reserved.
//

#import "GLLRenderWindowController.h"

#import "GLLView.h"
#import "GLLSceneDrawer.h"

@interface GLLRenderWindowController ()
{
	GLLSceneDrawer *drawer;
}

@end

@implementation GLLRenderWindowController

- (id)initWithManagedObjectContext:(NSManagedObjectContext *)context;
{
	if (!(self = [super initWithWindowNibName:@"GLLRenderWindowController"]))
		return nil;
	
	_managedObjectContext = context;
	
	return self;
}

- (void)windowDidLoad
{
    [super windowDidLoad];
    
	self.renderView.windowController = self;
}

- (void)openGLPrepared;
{
	drawer = [[GLLSceneDrawer alloc] initWithManagedObjectContext:self.managedObjectContext view:self.renderView];
}

- (NSString *)windowTitleForDocumentDisplayName:(NSString *)displayName
{
	return [NSString stringWithFormat:NSLocalizedString(@"%@ - Render view", @"render window title format"), displayName];
}

@end
