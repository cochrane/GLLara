//
//  GLLTextureAssignmentView.h
//  GLLara
//
//  Created by Torsten Kammer on 04.02.13.
//  Copyright (c) 2013 Torsten Kammer. All rights reserved.
//

#import <Cocoa/Cocoa.h>

@interface GLLTextureAssignmentView : NSTableCellView

@property (nonatomic) IBOutlet NSTextField *textureTitle;
@property (nonatomic) IBOutlet NSTextField *textureDescription;
@property (nonatomic) IBOutlet NSImageView *textureImage;

@end
