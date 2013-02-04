//
//  GLLTextureAssignmentView.h
//  GLLara
//
//  Created by Torsten Kammer on 04.02.13.
//  Copyright (c) 2013 Torsten Kammer. All rights reserved.
//

#import <Cocoa/Cocoa.h>

/*!
 * @abstract View to assign textures in the mesh edit view.
 * @discussion This class only contains a few outlets, to get access to the
 * subviews in a view-based table view.
 */
@interface GLLTextureAssignmentView : NSTableCellView

@property (nonatomic) IBOutlet NSTextField *textureTitle;
@property (nonatomic) IBOutlet NSTextField *textureDescription;
@property (nonatomic) IBOutlet NSImageView *textureImage;

@end
