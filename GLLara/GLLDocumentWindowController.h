//
//  GLLDocumentWindowController.h
//  GLLara
//
//  Created by Torsten Kammer on 05.09.12.
//  Copyright (c) 2012 Torsten Kammer. All rights reserved.
//

#import <Cocoa/Cocoa.h>

@class GLLSelection;

/*
 * @abstract Holds the document window.
 * @discussion Its main jobs involve being a data source and delegate for the source view (I didn't want to go to the trouble of dealing with an NSTreeController, and that sentence should tell you something's seriously wrong in AppKit). It also loads the view controllers for the various detail views and swaps them in and out, depending on what was selected.
 *
 * It also currently loads and removes meshes, although that job might be better situated in the document. That would just mean telling the document what was selected here, which becomes ugly very fast.
 */
@interface GLLDocumentWindowController : NSWindowController <NSOutlineViewDelegate, NSOutlineViewDataSource>

- (id)initWithManagedObjectContext:(NSManagedObjectContext *)managedObjectContext selection:(GLLSelection *)selection;

/* Utility methods for various drag sources that want to add files as new items */
- (NSDragOperation)itemDraggingEntered:(id<NSDraggingInfo>)sender;
- (BOOL)performItemDragOperation:(id<NSDraggingInfo>)sender;
- (BOOL)isImagePath:(NSURL *)url;

@property (nonatomic, retain, readonly) NSManagedObjectContext *managedObjectContext;

@property (nonatomic, retain) IBOutlet NSOutlineView *sourceView;
@property (nonatomic, retain) IBOutlet NSView *placeholderView;

@property (nonatomic, readonly) GLLSelection *selection;

@end
