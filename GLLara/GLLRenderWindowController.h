//
//  GLLRenderWindowController.h
//  GLLara
//
//  Created by Torsten Kammer on 05.09.12.
//  Copyright (c) 2012 Torsten Kammer. All rights reserved.
//

#import <Cocoa/Cocoa.h>

@class GLLCamera;
@class GLLScene;
@class GLLView;

@interface GLLRenderWindowController : NSWindowController <NSPopoverDelegate, NSWindowDelegate>

- (id)initWithCamera:(GLLCamera *)camera;

@property (nonatomic, retain, readonly) GLLCamera *camera;
@property (nonatomic, retain, readonly) NSManagedObjectContext *managedObjectContext;

@property (nonatomic, retain) IBOutlet GLLView *renderView;
@property (nonatomic, retain) IBOutlet NSPopover *popover;
@property (nonatomic, retain) IBOutlet NSButton *popoverButton;

- (IBAction)showPopoverFrom:(id)sender;

@end
