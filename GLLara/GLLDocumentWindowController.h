//
//  GLLDocumentWindowController.h
//  GLLara
//
//  Created by Torsten Kammer on 05.09.12.
//  Copyright (c) 2012 Torsten Kammer. All rights reserved.
//

#import <Cocoa/Cocoa.h>

@class GLLScene;

@interface GLLDocumentWindowController : NSWindowController <NSOutlineViewDataSource, NSOutlineViewDelegate>

- (id)initWithScene:(GLLScene *)scene;

@property (nonatomic, retain, readonly) GLLScene *scene;

@property (nonatomic, retain) IBOutlet NSOutlineView *sourceView;
@property (nonatomic, retain) IBOutlet NSView *placeholderView;
- (IBAction)loadMesh:(id)sender;

@end
