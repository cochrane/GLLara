//
//  GLLRenderWindowController.h
//  GLLara
//
//  Created by Torsten Kammer on 05.09.12.
//  Copyright (c) 2012 Torsten Kammer. All rights reserved.
//

#import <Cocoa/Cocoa.h>
#import <UniformTypeIdentifiers/UniformTypeIdentifiers.h>

@class GLLCamera;
@class GLLDocument;
@class GLLSceneDrawer;
@class GLLView;

/*!
 * @abstract Controls a render view.
 * @discussion The Render View controller handles the window for a render view. It shows popups for features, holds the camera, provides sources for the controllers and does some general management.
 */
@interface GLLRenderWindowController : NSWindowController <NSPopoverDelegate, NSWindowDelegate>

- (id)initWithCamera:(GLLCamera *)camera sceneDrawer:(GLLSceneDrawer *)sceneDrawer;

@property (nonatomic, retain, readonly) GLLCamera *camera;
@property (nonatomic, retain, readonly) GLLSceneDrawer *sceneDrawer;
@property (nonatomic, retain, readonly) NSManagedObjectContext *managedObjectContext;

@property (nonatomic, retain) IBOutlet GLLView *renderView;
@property (nonatomic, retain) IBOutlet NSPopover *popover;
@property (nonatomic, retain) IBOutlet NSButton *popoverButton;
@property (nonatomic, retain) IBOutlet NSSegmentedControl *selectionModeControl;

- (IBAction)showPopoverFrom:(id)sender;
- (IBAction)renderToFile:(id)sender;

@end
