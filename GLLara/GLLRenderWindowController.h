//
//  GLLRenderWindowController.h
//  GLLara
//
//  Created by Torsten Kammer on 05.09.12.
//  Copyright (c) 2012 Torsten Kammer. All rights reserved.
//

#import <AppKit/NSWindowController.h>

@class GLLScene;
@class GLLView;

@interface GLLRenderWindowController : NSWindowController

- (id)initWithScene:(GLLScene *)scene;

@property (nonatomic, weak, readonly) GLLScene *scene;

@property (nonatomic, retain) IBOutlet GLLView *renderView;

// Called by the GLLView once it's context is ready and set up.
- (void)openGLPrepared;

@end
