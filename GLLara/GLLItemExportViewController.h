//
//  GLLItemExportViewController.h
//  GLLara
//
//  Created by Torsten Kammer on 19.09.12.
//  Copyright (c) 2012 Torsten Kammer. All rights reserved.
//

#import <Cocoa/Cocoa.h>

/*!
 * @abstract Provides accessory view for exporting posed items to OBJ.
 * @discussion Just a simple holder view controller that passes its values on.
 */
@interface GLLItemExportViewController : NSViewController

@property (nonatomic) BOOL includeTransformations;
@property (nonatomic) BOOL includeVertexColors;
@property (nonatomic) BOOL canExportAllData;

@end
