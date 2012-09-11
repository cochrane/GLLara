//
//  GLLView.m
//  GLLara
//
//  Created by Torsten Kammer on 04.09.12.
//  Copyright (c) 2012 Torsten Kammer. All rights reserved.
//

#import "GLLView.h"

#import <OpenGL/gl3.h>
#import <OpenGL/gl3ext.h>

#import "GLLCamera.h"
#import "GLLSceneDrawer.h"
#import "GLLRenderWindowController.h"
#import "GLLResourceManager.h"

@interface GLLView ()
{
	BOOL openGLPrepared;
	BOOL inGesture;
}

@end

@implementation GLLView

- (id)initWithFrame:(NSRect)frame
{
	// Not calling initWithFrame:pixelFormat:, because we set up our own context.
	if (!(self = [super initWithFrame:frame])) return nil;
	
	NSOpenGLPixelFormatAttribute attribs[] = {
		NSOpenGLPFADoubleBuffer,
		NSOpenGLPFADepthSize, 24,
		NSOpenGLPFAOpenGLProfile, NSOpenGLProfileVersion3_2Core,
		NSOpenGLPFAMultisample, 1,
		NSOpenGLPFASampleBuffers, 1,
		NSOpenGLPFASamples, 8,
		0
	};
	
	NSOpenGLPixelFormat *format = [[NSOpenGLPixelFormat alloc] initWithAttributes:attribs];
	NSOpenGLContext *context = [[NSOpenGLContext alloc] initWithFormat:format shareContext:[[GLLResourceManager sharedResourceManager] openGLContext]];
	[self setOpenGLContext:context];
	[context setView:self];
	[self setWantsBestResolutionOpenGLSurface:YES];
	
	return self;
}

- (void)prepareOpenGL
{
	openGLPrepared = YES;
	[self.windowController openGLPrepared];
}

- (void)setWindowController:(GLLRenderWindowController *)windowController
{
	NSAssert(!_windowController, @"Can't set window controller twice");
	
	_windowController = windowController;
	if (openGLPrepared) [_windowController openGLPrepared];
}

- (void)rotateWithEvent:(NSEvent *)event
{
	if (self.camera.cameraLocked) return;
	
	float angle = event.rotation * M_PI / 180.0;
	self.camera.longitude -= angle;
}

- (void)magnifyWithEvent:(NSEvent *)event
{
	if (self.camera.cameraLocked) return;
	
	self.camera.distance *= 1 + event.magnification;
}

- (void)beginGestureWithEvent:(NSEvent *)event
{
	inGesture = YES;
	[self.camera.managedObjectContext.undoManager beginUndoGrouping];
	[self.camera.managedObjectContext.undoManager setActionIsDiscardable:YES];
}
- (void)endGestureWithEvent:(NSEvent *)event
{
	inGesture = NO;
	[self.camera.managedObjectContext.undoManager setActionName:NSLocalizedString(@"Camera changed", @"Undo: data of camera has changed.")];
	[self.camera.managedObjectContext.undoManager endUndoGrouping];
}

- (void)scrollWheel:(NSEvent *)theEvent
{
	if (self.camera.cameraLocked) return;
	
	self.camera.currentPositionX += theEvent.deltaX / self.bounds.size.width;
	self.camera.currentPositionZ += theEvent.deltaY / self.bounds.size.height;
}

- (void)reshape
{
	// Set height and width for camera.
	// Note: This is points, not pixels. Pixels are used for glViewport exclusively.
	self.camera.actualWindowWidth = self.bounds.size.width;
	self.camera.actualWindowHeight = self.bounds.size.height;
	
	NSRect actualPixels = [self convertRectToBacking:[self bounds]];
	glViewport(0, 0, actualPixels.size.width, actualPixels.size.height);
}

- (void)drawRect:(NSRect)dirtyRect
{
	[self.sceneDrawer draw];
	[self.openGLContext flushBuffer];
}

@end
