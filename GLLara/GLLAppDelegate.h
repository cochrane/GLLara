//
//  GLLAppDelegate.h
//  GLLara
//
//  Created by Torsten Kammer on 01.12.15.
//  Copyright (c) 2015 Torsten Kammer. All rights reserved.
//

#import <Foundation/Foundation.h>

@class GLLPreferencesWindowController;

@interface GLLAppDelegate : NSObject

@property (nonatomic, retain) GLLPreferencesWindowController *preferencesWindowController;

- (IBAction)openPreferences:(id)sender;

@end
