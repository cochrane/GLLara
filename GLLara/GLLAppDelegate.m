//
//  GLLAppDelegate.m
//  GLLara
//
//  Created by Torsten Kammer on 01.12.15.
//  Copyright (c) 2015 Torsten Kammer. All rights reserved.
//

#import "GLLAppDelegate.h"

#import "GLLPreferencesWindowController.h"

@implementation GLLAppDelegate

- (void)awakeFromNib
{
    [[NSUserDefaults standardUserDefaults] registerDefaults:@{
        @"UseAnisotropy": @(YES),
        @"UseMultisampling": @(YES),
        @"AnisotropyAmount": @(4),
        @"MultiSamplingAmount": @(4)
    }];
}

- (IBAction)openPreferences:(id)sender;
{
    if (!self.preferencesWindowController) {
        self.preferencesWindowController = [[GLLPreferencesWindowController alloc] init];
    }
    
    [self.preferencesWindowController showWindow:sender];
}

@end
