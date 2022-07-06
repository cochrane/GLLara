//
//  GLLView.h
//  GLLara
//
//  Created by Torsten Kammer on 04.09.12.
//  Copyright (c) 2012 Torsten Kammer. All rights reserved.
//

#import <Cocoa/Cocoa.h>
#import <MetalKit/MetalKit.h>

@class GLLCamera;
@class GLLDocument;
@class GLLSceneDrawer;
@class GLLViewDrawer;

/*!
 * @abstract Draws a scene, based on a camera.
 * @discussion The GLLView doesn't do a lot itself; it mostly handles user input and provides a context for the scene drawer. This context is always shared with the Resource Manager; as a result, all GLLViews share their contexts (right now, the code does not take full advantage of that). Rendering from background threads should be safe now, but this requires more investigation.
 *
 * A view always belongs to one camera. The camera stores its own information, and the size that the view should have, as well as its number. You can change a view's camera, but doing so will confuse a lot of people, so don't.
 *
 * The view does not render automatically. Instead, the Scene Drawer does a setNeedsDisplay: when the scene has changed.
 */
@interface GLLView : MTKView

- (void)setCamera:(GLLCamera *)camera sceneDrawer:(GLLSceneDrawer *)sceneDrawer;

@property (nonatomic, retain, readonly) GLLCamera *camera;
@property (nonatomic, weak) GLLDocument *document;
@property (nonatomic, retain, readonly) GLLSceneDrawer *sceneDrawer;
@property (nonatomic, retain, readonly) GLLViewDrawer *viewDrawer;
@property (nonatomic, assign) BOOL showSelection;

- (void)unload;

@end
