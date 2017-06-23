//
//  GLLDropTargetView.m
//  GLLara
//
//  Created by Torsten Kammer on 22.06.17.
//  Copyright © 2017 Torsten Kammer. All rights reserved.
//

#import "GLLDropTargetView.h"

#import "GLLDocument.h"
#import "GLLDocumentWindowController.h"

@implementation GLLDropTargetView

- (void)awakeFromNib {
    [self registerForDraggedTypes:@[ (__bridge NSString*) kUTTypeFileURL ]];
}

- (NSDragOperation)draggingEntered:(id<NSDraggingInfo>)sender {
    GLLDocumentWindowController *windowController = self.window.windowController;
    return [windowController itemDraggingEntered:sender];
}

- (BOOL)performDragOperation:(id<NSDraggingInfo>)sender {
    GLLDocumentWindowController *windowController = self.window.windowController;
    return [windowController performItemDragOperation:sender];
}

@end
