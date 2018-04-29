//
//  GLLPreferencesWindowController.h
//  GLLara
//
//  Created by Torsten Kammer on 01.12.15.
//  Copyright (c) 2015 Torsten Kammer. All rights reserved.
//

#import <Cocoa/Cocoa.h>

@interface GLLPreferencesWindowController : NSWindowController <NSPageControllerDelegate>

@property (nonatomic, retain) IBOutlet NSPageController *pageController;
@property (nonatomic, retain) IBOutlet NSToolbar *toolbar;

- (IBAction)navigateToPage:(id)sender;

@end
