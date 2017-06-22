//
//  GLLDropTargetView.m
//  GLLara
//
//  Created by Torsten Kammer on 22.06.17.
//  Copyright © 2017 Torsten Kammer. All rights reserved.
//

#import "GLLDropTargetView.h"

#import "GLLDocument.h"

@implementation GLLDropTargetView

- (void)awakeFromNib {
    [self registerForDraggedTypes:@[ (__bridge NSString*) kUTTypeFileURL ]];
}

- (NSDragOperation)draggingEntered:(id<NSDraggingInfo>)sender {
    NSWindowController *windowController = self.window.windowController;
    GLLDocument *document = (GLLDocument *) windowController.document;
    if (!document) {
        return NSDragOperationNone;
    }
    
    NSPasteboard *pasteboard = sender.draggingPasteboard;
    for (NSPasteboardItem *item in pasteboard.pasteboardItems) {
        // Wait, does Apple really not have a method to get multiple URLs from
        // the pasteboard? I'm not complaining, just surprised.
        NSString *urlAsString = [item stringForType:(__bridge NSString*) kUTTypeFileURL];
        NSURL *url = [NSURL URLWithString:urlAsString];
        NSString *filename = [url filePathURL].lastPathComponent.lowercaseString;
        
        // Note: Not using dedicated methods because they can't deal with the
        // double extension that XNALara uses.
        if (![filename hasSuffix:@".mesh"] && ![filename hasSuffix:@".mesh.ascii"] && ![filename hasSuffix:@".xps"] && ![filename hasSuffix:@".obj"]) {
            return NSDragOperationNone;
        }
    }
    
    return NSDragOperationCopy;
}

- (BOOL)performDragOperation:(id<NSDraggingInfo>)sender {
    NSWindowController *windowController = self.window.windowController;
    GLLDocument *document = (GLLDocument *) windowController.document;
    if (!document) {
        return NO;
    }
    
    NSPasteboard *pasteboard = sender.draggingPasteboard;
    for (NSPasteboardItem *item in pasteboard.pasteboardItems) {
        // Wait, does Apple really not have a method to get multiple URLs from
        // the pasteboard? I'm not complaining, just surprised.
        NSString *urlAsString = [item stringForType:(__bridge NSString*) kUTTypeFileURL];
        NSURL *url = [NSURL URLWithString:urlAsString];
        
        NSError *error = nil;
        [document addModelAtURL:url error:&error];
        if (error) {
            [self presentError:error];
            return NO;
        }
    }
    
    return YES;
}

@end
