//
//  GLLMeshViewController.h
//  GLLara
//
//  Created by Torsten Kammer on 06.09.12.
//  Copyright (c) 2012 Torsten Kammer. All rights reserved.
//

#import <Cocoa/Cocoa.h>

#import "GLLMultipleSelectionPlaceholder.h"

@class GLLSelection;

/*
 * @abstract View controller for a mesh.
 * @discussion The main logic included here is to provide the views for the view-based NSTableView.
 */
@interface GLLMeshViewController : NSViewController <NSTableViewDataSource, NSTableViewDelegate>

- (id)initWithSelection:(GLLSelection *)selection managedObjectContext:(NSManagedObjectContext *)context;

@property (nonatomic, assign) IBOutlet NSTableView *renderParametersView;
@property (nonatomic, assign) IBOutlet NSTableView *textureAssignmentsView;

@property (nonatomic, readonly) GLLMultipleSelectionPlaceholder *visible;
@property (nonatomic, readonly) GLLMultipleSelectionPlaceholder *usingBlending;
@property (nonatomic, readonly) GLLMultipleSelectionPlaceholder *selectedShader;
@property (nonatomic, readonly) GLLMultipleSelectionPlaceholder *cullFace;

@property (nonatomic, readonly) GLLSelection *selection;

@property (nonatomic) NSArray *possibleShaders;

@property (nonatomic, readonly) NSManagedObjectContext *managedObjectContext;

// Help
- (IBAction)help:(id)sender;

@end
