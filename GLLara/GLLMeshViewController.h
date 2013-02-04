//
//  GLLMeshViewController.h
//  GLLara
//
//  Created by Torsten Kammer on 06.09.12.
//  Copyright (c) 2012 Torsten Kammer. All rights reserved.
//

#import <Cocoa/Cocoa.h>

/*
 * @abstract View controller for a mesh.
 * @discussion The main logic included here is to provide the views for the view-based NSTableView. Yeah, that's not a lot.
 */
@interface GLLMeshViewController : NSViewController <NSTableViewDataSource, NSTableViewDelegate>

@property (nonatomic, assign) IBOutlet NSTableView *renderParametersView;
@property (nonatomic, assign) IBOutlet NSTableView *textureAssignmentsView;

@property (nonatomic) NSArray *selectedMeshes;

@end
