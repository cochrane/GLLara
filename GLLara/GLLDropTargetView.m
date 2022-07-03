//
//  GLLDropTargetView.m
//  GLLara
//
//  Created by Torsten Kammer on 22.06.17.
//  Copyright © 2017 Torsten Kammer. All rights reserved.
//

#import "GLLDropTargetView.h"

#import <UniformTypeIdentifiers/UniformTypeIdentifiers.h>

#import "GLLDocument.h"
#import "GLLDocumentWindowController.h"
#import "GLLItemDragDestination.h"

@interface GLLDropTargetView()

@property (nonatomic, retain) GLLItemDragDestination *dragDestination;
    
@end

@implementation GLLDropTargetView

- (void)awakeFromNib {
    [self registerForDraggedTypes:@[ UTTypeFileURL.identifier ]];
    self.dragDestination = [[GLLItemDragDestination alloc] init];
}

- (NSDragOperation)draggingEntered:(id<NSDraggingInfo>)sender {
    GLLDocumentWindowController *windowController = self.window.windowController;
    self.dragDestination.document = windowController.document;
    
    return [self.dragDestination itemDraggingEntered:sender];
}

- (BOOL)performDragOperation:(id<NSDraggingInfo>)sender {
    GLLDocumentWindowController *windowController = self.window.windowController;
    self.dragDestination.document = windowController.document;
    
    NSError *error = nil;
    BOOL success = [self.dragDestination performItemDragOperation:sender error:&error];
    if (!success && error)
        [self presentError:error];
    return success;
}

@end
