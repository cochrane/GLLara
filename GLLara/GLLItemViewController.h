//
//  GLLItemViewController.h
//  GLLara
//
//  Created by Torsten Kammer on 11.09.12.
//  Copyright (c) 2012 Torsten Kammer. All rights reserved.
//

#import <Cocoa/Cocoa.h>

@interface GLLItemViewController : NSViewController

@property (nonatomic) NSArray *selectedItems;

- (IBAction)loadPose:(id)sender;
- (IBAction)loadChildModel:(id)sender;

@end
