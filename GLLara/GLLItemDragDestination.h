//
//  GLLItemDragDestination.h
//  GLLara
//
//  Created by Torsten Kammer on 23.06.17.
//  Copyright © 2017 Torsten Kammer. All rights reserved.
//

#import <Cocoa/Cocoa.h>

@class GLLDocument;

@interface GLLItemDragDestination : NSObject

@property (nonatomic, weak) GLLDocument *document;

/* Utility methods for various drag sources that want to add files as new items */
- (NSDragOperation)itemDraggingEntered:(id<NSDraggingInfo>)sender;
- (BOOL)performItemDragOperation:(id<NSDraggingInfo>)sender error:(NSError *__autoreleasing*)error;
- (BOOL)isImagePath:(NSURL *)url;

@end
