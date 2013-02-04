//
//  GLLItemViewController.h
//  GLLara
//
//  Created by Torsten Kammer on 11.09.12.
//  Copyright (c) 2012 Torsten Kammer. All rights reserved.
//

#import <Cocoa/Cocoa.h>

/*!
 * @abstract View controller for an item.
 * @discussions Main functions include loading poses, child models and (in the
 * future) texture packs.
 */
@interface GLLItemViewController : NSViewController

@property (nonatomic) NSArray *selectedItems;

- (IBAction)loadPose:(id)sender;
- (IBAction)loadChildModel:(id)sender;

@end
