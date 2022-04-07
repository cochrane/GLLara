//
//  GLLViewDrawer.h
//  GLLara
//
//  Created by Torsten Kammer on 26.09.12.
//  Copyright (c) 2012 Torsten Kammer. All rights reserved.
//

#import <Cocoa/Cocoa.h>
#import <MetalKit/MetalKit.h>

@class GLLCamera;
@class GLLSceneDrawer;
@class GLLView;

/*!
 * @abstract Drawer for a single context.
 * @discussion This drawer manages a context's state and is always associated
 * with one view. For actual display, it uses a shared scene drawer. It also
 * handles rendering to files.
 */
@interface GLLViewDrawer : NSObject <MTKViewDelegate>

- (id)initWithManagedSceneDrawer:(GLLSceneDrawer *)drawer camera:(GLLCamera *)camera view:(GLLView *)view;

@property (nonatomic, retain) GLLCamera *camera;
@property (nonatomic, weak, readonly) GLLView *view;
@property (nonatomic, readonly) GLLSceneDrawer *sceneDrawer;

- (void)drawShowingSelection:(BOOL)selection resetState:(BOOL)reset;

// Basic support for render to file
- (void)writeImageToURL:(NSURL *)url fileType:(NSString *)type size:(CGSize)size;
- (void)renderImageOfSize:(CGSize)size toColorBuffer:(void *)colorData;

@end
