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

#import "GLLResourceManager.h"

@implementation GLLView

- (id)initWithFrame:(NSRect)frame
{
	NSOpenGLPixelFormatAttribute attribs[] = {
		NSOpenGLPFADoubleBuffer,
		NSOpenGLPFADepthSize, 24,
		NSOpenGLPFAOpenGLProfile, NSOpenGLProfileVersion3_2Core,
		0
	};
	
	NSOpenGLPixelFormat *format = [[NSOpenGLPixelFormat alloc] initWithAttributes:attribs];
	
	if (!(self = [super initWithFrame:frame pixelFormat:format])) return nil;
	
	return self;
}

- (void)prepareOpenGL
{
	_resourceManager = [[GLLResourceManager alloc] init];
	
	glClearColor(0.5, 0.5, 0.5, 1.0);
}

- (void)reshape
{
	glViewport(0, 0, self.bounds.size.width, self.bounds.size.height);
}

- (void)drawRect:(NSRect)dirtyRect
{
	glClear(GL_COLOR_BUFFER_BIT | GL_DEPTH_BUFFER_BIT);
	
	[self.openGLContext flushBuffer];
}

@end
