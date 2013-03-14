//
//  GLLRenderWindow.m
//  GLLara
//
//  Created by Torsten Kammer on 01.03.13.
//  Copyright (c) 2013 Torsten Kammer. All rights reserved.
//

#import "GLLRenderWindow.h"

#import "GLLCamera.h"
#import "GLLView.h"

@implementation GLLRenderWindow

- (GLLCamera *)camera
{
	return self.renderView.camera;
}

- (BOOL)scriptingLocked
{
	return self.camera.windowSizeLocked;
}
- (void)setScriptingLocked:(BOOL)scriptingLocked
{
	self.camera.windowSizeLocked = scriptingLocked;
}

- (CGFloat)scriptingHeight
{
	return self.camera.latestWindowHeight;
}
- (void)setScriptingHeight:(CGFloat)scriptingHeight
{
	self.camera.latestWindowHeight = scriptingHeight;
}

- (CGFloat)scriptingWidth
{
	return self.camera.latestWindowWidth;
}
- (void)setScriptingWidth:(CGFloat)scriptingWidth
{
	self.camera.latestWindowWidth = scriptingWidth;
}

@end
