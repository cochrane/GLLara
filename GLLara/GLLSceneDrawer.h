//
//  GLLSceneDrawer.h
//  GLLara
//
//  Created by Torsten Kammer on 03.09.12.
//  Copyright (c) 2012 Torsten Kammer. All rights reserved.
//

#import <Foundation/Foundation.h>

@class GLLResourceManager;
@class GLLScene;
@class GLLView;

@interface GLLSceneDrawer : NSObject

- (id)initWithScene:(GLLScene *)scene view:(GLLView *)view;

@property (nonatomic, retain, readonly) GLLScene *scene;
@property (nonatomic, retain, readonly) GLLResourceManager *resourceManager;
@property (nonatomic, weak, readonly) GLLView *view;

- (void)setWindowSize:(NSSize)size;

- (void)draw;

/*
 * You cannot release OpenGL objects in dealloc. It sounds like a good idea, but there is no guarantee that an OpenGL context (or the right one!) is set. Autorelease-pools can help make it all more complicated. Instead, this method explicitly unloads all data. Clients (in particular the GLLView) can and have to ensure that the right OpenGL Context is set.
 */
- (void)unload;

@end
