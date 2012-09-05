//
//  GLLRenderWindowController.m
//  GLLara
//
//  Created by Torsten Kammer on 05.09.12.
//  Copyright (c) 2012 Torsten Kammer. All rights reserved.
//

#import "GLLRenderWindowController.h"

#import "GLLView.h"
#import "GLLScene.h"
#import "GLLSceneDrawer.h"

@interface GLLRenderWindowController ()
{
	GLLSceneDrawer *drawer;
}

@end

@implementation GLLRenderWindowController

- (id)initWithScene:(GLLScene *)scene;
{
	if (!(self = [super initWithWindowNibName:@"GLLRenderWindowController"]))
		return nil;
	
	_scene = scene;
	
	return self;
}

- (void)windowDidLoad
{
    [super windowDidLoad];
    
	self.renderView.windowController = self;
}

- (void)openGLPrepared;
{
	drawer = [[GLLSceneDrawer alloc] initWithScene:self.scene view:self.renderView];
}

@end
