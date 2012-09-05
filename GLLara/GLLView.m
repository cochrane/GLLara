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

#import "GLLSceneDrawer.h"
#import "GLLResourceManager.h"

@implementation GLLView

- (id)initWithFrame:(NSRect)frame
{
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
	
	if (!(self = [super initWithFrame:frame pixelFormat:format])) return nil;
	
	return self;
}

- (void)prepareOpenGL
{
	_resourceManager = [[GLLResourceManager alloc] init];
	self.sceneDrawer.resourceManager = _resourceManager;
}

- (void)reshape
{
	[self.sceneDrawer setWindowSize:self.bounds.size];
}

- (void)drawRect:(NSRect)dirtyRect
{
	[self.sceneDrawer draw];
	
	[self.openGLContext flushBuffer];
}

@end
