//
//  GLLView.h
//  GLLara
//
//  Created by Torsten Kammer on 04.09.12.
//  Copyright (c) 2012 Torsten Kammer. All rights reserved.
//

// Cocoa.h conflicts with gl3.h, because it includes AppKit, which includes Core Image, which includes Core Video, which includes gl.h. A bug is filed as rdar://12227623
#import <AppKit/NSOpenGL.h>
#import <AppKit/NSOpenGLView.h>

@class GLLCamera;
@class GLLSceneDrawer;
@class GLLRenderWindowController;

@interface GLLView : NSOpenGLView

@property (nonatomic, retain) GLLCamera *camera;
@property (nonatomic, weak) GLLRenderWindowController *windowController;

@property (nonatomic, retain) GLLSceneDrawer *sceneDrawer;

@end
