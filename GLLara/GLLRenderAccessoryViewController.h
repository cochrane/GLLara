//
//  GLLRenderAccessoryViewController.h
//  GLLara
//
//  Created by Torsten Kammer on 14.09.12.
//  Copyright (c) 2012 Torsten Kammer. All rights reserved.
//

#import <Cocoa/Cocoa.h>

@class GLLRenderViewAccessoryControllerFileType;

/*!
 * @abstract Provides accessory view for exporting images.
 * @discussion This controller provides the accessory view for the save panel
 * for exporting images, and returns the selected file type as UTI.
 */
@interface GLLRenderAccessoryViewController : NSViewController

@property (nonatomic) NSSavePanel *savePanel;
@property (nonatomic, readonly) NSString *selectedTypeIdentifier;

@property (nonatomic) NSArray<GLLRenderViewAccessoryControllerFileType *> *fileTypes;
@property (nonatomic) GLLRenderViewAccessoryControllerFileType *selectedFileType;

@end
