//
//  GLLItemDragDestination.m
//  GLLara
//
//  Created by Torsten Kammer on 23.06.17.
//  Copyright © 2017 Torsten Kammer. All rights reserved.
//

#import "GLLItemDragDestination.h"

#import "GLLDocument.h"
#import "GLLItem.h"
#import "GLLSelection.h"

@interface GLLItemDragDestination()

- (GLLItem *)itemForPose;

@end

@implementation GLLItemDragDestination

- (NSDragOperation)itemDraggingEntered:(id<NSDraggingInfo>)sender {
    GLLDocument *document = (GLLDocument *) self.document;
    if (!document) {
        return NSDragOperationNone;
    }
    
    NSPasteboard *pasteboard = sender.draggingPasteboard;
    for (NSPasteboardItem *item in pasteboard.pasteboardItems) {
        // Wait, does Apple really not have a method to get multiple URLs from
        // the pasteboard? I'm not complaining, just surprised.
        NSString *urlAsString = [item stringForType:(__bridge NSString*) kUTTypeFileURL];
        NSURL *url = [NSURL URLWithString:urlAsString].filePathURL;
        NSString *filename = url.lastPathComponent.lowercaseString;
        
        BOOL validFile = NO;
        // Check whether this is a model
        // Note: Not using dedicated methods because they can't deal with the
        // double extension that XNALara uses.
        if ([filename hasSuffix:@".mesh"] || [filename hasSuffix:@".mesh.ascii"] || [filename hasSuffix:@".xps"] || [filename hasSuffix:@".obj"]) {
            validFile = YES;
        }
        
        // Check whether this is a pose file and the document has a model that it can be applied to
        if ([filename hasSuffix:@"pose"] && self.itemForPose) {
            validFile = YES;
        }
        
        // Check whether this is an image path
        if ([self isImagePath:url.filePathURL]) {
            validFile = YES;
        }
        if (!validFile)
            return NSDragOperationNone;
    }
    
    return NSDragOperationCopy;
}

- (GLLItem *)itemForPose {
    GLLDocument *document = (GLLDocument *) self.document;
    if (!document) {
        return nil;
    }
    
    if (document.selection.countOfSelectedItems == 1) {
        return [document.selection objectInSelectedItemsAtIndex: 0];
    }
    
    // Okay, more complicated: Check if there is only item in the file
    NSFetchRequest *itemRequest = [NSFetchRequest fetchRequestWithEntityName:@"GLLItem"];;
    itemRequest.predicate = [NSPredicate predicateWithFormat:@"parent == nil"];
    
    NSArray *allRootItems = [document.managedObjectContext executeFetchRequest:itemRequest error:NULL];
    if (allRootItems.count == 1) {
        return allRootItems.firstObject;
    }
    
    // Unclear, not allowed
    return nil;
}

- (BOOL)isImagePath:(NSURL *)url {
    NSString *extension = url.pathExtension;
    if (!extension)
        return NO;
    
    // Check whether this is a DDS file
    if ([extension isEqualToString:@"dds"])
        return YES;
    
    // Try to find image type
    NSString *typeId = CFBridgingRelease(UTTypeCreatePreferredIdentifierForTag(kUTTagClassFilenameExtension, (__bridge CFStringRef) extension, kUTTypeImage));
    if (!typeId)
        return NO;
    
    NSArray *imageSourceTypes = (__bridge_transfer NSArray *) CGImageSourceCopyTypeIdentifiers();
    return [imageSourceTypes containsObject:typeId];
}

- (BOOL)performItemDragOperation:(id<NSDraggingInfo>)sender error:(NSError *__autoreleasing*)error {
    GLLDocument *document = (GLLDocument *) self.document;
    if (!document) {
        return NO;
    }
    
    NSPasteboard *pasteboard = sender.draggingPasteboard;
    for (NSPasteboardItem *item in pasteboard.pasteboardItems) {
        // Wait, does Apple really not have a method to get multiple URLs from
        // the pasteboard? I'm not complaining, just surprised.
        NSString *urlAsString = [item stringForType:(__bridge NSString*) kUTTypeFileURL];
        NSURL *url = [NSURL URLWithString:urlAsString].filePathURL;
        
        NSError *ourError = 0;
        GLLItem *item = self.itemForPose;
        if ([self isImagePath:url]) {
            [document addImagePlane:url error:&ourError];
        } else if ([url.lastPathComponent.lowercaseString hasSuffix:@"pose"] && item) {
            [item loadPoseFrom:url error:&ourError];
        } else {
            [document addModelAtURL:url error:&ourError];
        }
        if (ourError) {
            // Hand out error only if requested
            if (error) {
                *error = ourError;
            }
            return NO;
        }
    }
    
    return YES;
}

@end
