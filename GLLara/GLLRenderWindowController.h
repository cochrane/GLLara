//
//  GLLRenderWindowController.h
//  GLLara
//
//  Created by Torsten Kammer on 05.09.12.
//  Copyright (c) 2012 Torsten Kammer. All rights reserved.
//

#import <AppKit/NSArrayController.h>
#import <AppKit/NSWindowController.h>
#import <AppKit/NSPopover.h>
#import <CoreData/CoreData.h>

@class GLLCamera;
@class GLLScene;
@class GLLView;

@interface GLLRenderWindowController : NSWindowController <NSPopoverDelegate>

- (id)initWithCamera:(GLLCamera *)camera;

@property (nonatomic, retain, readonly) GLLCamera *camera;
@property (nonatomic, retain, readonly) NSManagedObjectContext *managedObjectContext;

@property (nonatomic, retain) IBOutlet GLLView *renderView;
@property (nonatomic, retain) IBOutlet NSPopover *popover;


@property (nonatomic, retain) NSArrayController *itemsController;
@property (nonatomic) id selectedObject;
@property (nonatomic, retain, readonly) NSPredicate *targetsFilterPredicate;


- (IBAction)showPopoverFrom:(id)sender;

// Called by the GLLView once it's context is ready and set up.
- (void)openGLPrepared;

@end
