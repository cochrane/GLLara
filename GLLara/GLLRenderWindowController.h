//
//  GLLRenderWindowController.h
//  GLLara
//
//  Created by Torsten Kammer on 05.09.12.
//  Copyright (c) 2012 Torsten Kammer. All rights reserved.
//

#import <AppKit/NSWindowController.h>
#import <CoreData/CoreData.h>

@class GLLScene;
@class GLLView;

@interface GLLRenderWindowController : NSWindowController

- (id)initWithManagedObjectContext:(NSManagedObjectContext *)context;

@property (nonatomic, retain, readonly) NSManagedObjectContext *managedObjectContext;

@property (nonatomic, retain) IBOutlet GLLView *renderView;

// Called by the GLLView once it's context is ready and set up.
- (void)openGLPrepared;

@end
