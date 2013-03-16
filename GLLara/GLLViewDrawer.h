//
//  GLLViewDrawer.h
//  GLLara
//
//  Created by Torsten Kammer on 26.09.12.
//  Copyright (c) 2012 Torsten Kammer. All rights reserved.
//

#import <AppKit/NSView.h>
#import <AppKit/NSOpenGL.h>
#import <Foundation/Foundation.h>

@class GLLCamera;
@class GLLView;
@class GLLSceneDrawer;

/*!
 * @abstract Drawer for a single context.
 * @discussion This drawer manages a context's state and is always associated
 * with one view. For actual display, it uses a shared scene drawer. It also
 * handles rendering to files.
 */
@interface GLLViewDrawer : NSObject

- (id)initWithManagedSceneDrawer:(GLLSceneDrawer *)drawer camera:(GLLCamera *)camera context:(NSOpenGLContext *)openGLContext pixelFormat:(NSOpenGLPixelFormat *)format;

@property (nonatomic, retain) GLLCamera *camera;
@property (nonatomic, weak) NSView *view;
@property (nonatomic, retain) NSOpenGLContext *context;
@property (nonatomic, retain) NSOpenGLPixelFormat *pixelFormat;
@property (nonatomic, readonly) GLLSceneDrawer *sceneDrawer;

- (void)drawShowingSelection:(BOOL)selection;

// Basic support for render to file
- (void)writeImageToURL:(NSURL *)url fileType:(NSString *)type size:(CGSize)size;
- (void)renderImageOfSize:(CGSize)size toColorBuffer:(void *)colorData;
- (CGImageRef)createImageOfSize:(CGSize)size;

@end
