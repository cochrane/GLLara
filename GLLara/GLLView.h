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

@class GLLResourceManager;

@interface GLLView : NSOpenGLView

@property (nonatomic, retain, readonly) GLLResourceManager *resourceManager;

@end
