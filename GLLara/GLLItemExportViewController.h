//
//  GLLItemExportViewController.h
//  GLLara
//
//  Created by Torsten Kammer on 19.09.12.
//  Copyright (c) 2012 Torsten Kammer. All rights reserved.
//

#import <Cocoa/Cocoa.h>

@interface GLLItemExportViewController : NSViewController

@property (nonatomic) BOOL includeTransformations;
@property (nonatomic) BOOL includeVertexColors;
@property (nonatomic) BOOL canExportAllData;

@end
