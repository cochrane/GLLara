//
//  GLLAppDelegate.m
//  GLLara
//
//  Created by Torsten Kammer on 01.12.15.
//  Copyright (c) 2015 Torsten Kammer. All rights reserved.
//

#import "GLLAppDelegate.h"

#import "GLLPreferenceKeys.h"
#import "GLLPreferencesWindowController.h"
#import "GLLara-Swift.h"

@interface GLLAppDelegate() {
    GLLHIDManager *manager;
}

@end

@implementation GLLAppDelegate

- (void)awakeFromNib
{
    [[NSUserDefaults standardUserDefaults] registerDefaults:@{
        GLLPrefUseAnisotropy: @(YES),
        GLLPrefUseMSAA: @(YES),
        GLLPrefAnisotropyAmount: @(4),
        GLLPrefMSAAAmount: @(4),
        GLLPrefObjExportIncludesTransforms: @(YES),
        GLLPrefObjExportIncludesVertexColors: @(NO),
        GLLPrefPoseExportIncludesUnused: @(NO),
        GLLPrefPoseExportOnlySelected: @(YES),
        GLLPrefShowSkeleton: @(YES)
    }];
    
    manager = [[GLLHIDManager alloc] init];
}

- (IBAction)openPreferences:(id)sender;
{
    if (!self.preferencesWindowController) {
        self.preferencesWindowController = [[GLLPreferencesWindowController alloc] init];
    }
    
    [self.preferencesWindowController showWindow:sender];
}

@end
