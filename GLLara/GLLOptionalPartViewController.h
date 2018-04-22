//
//  GLLOptionalPartViewController.h
//  GLLara
//
//  Created by Torsten Kammer on 18.04.18.
//  Copyright © 2018 Torsten Kammer. All rights reserved.
//

#import <Cocoa/Cocoa.h>

@class GLLOptionalPart;

@interface GLLOptionalPartViewController : NSViewController

@property (nonatomic, retain) IBOutlet NSTableView *tableView;

@property (nonatomic, copy) NSArray<GLLOptionalPart *> *parts;

@end
